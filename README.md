# Hyperlinked

A Ruby client for [HAL](https://stateless.co/hal_specification.html)-based hypermedia APIs. Navigate any API that follows the HAL (`application/hal+json`) format using link relations, embedded resources, URI templates, and standard HTTP caching — with no coupling to a specific API host.

## Installation

```ruby
gem 'hyperlinked'
```

Or install it yourself:

```
$ gem install hyperlinked
```

## Usage

### Configure

```ruby
Hyperlinked.configure do |c|
  # Required: the root URL of your API
  c.api_root = 'https://api.example.com/v1'

  # Required for OAuth2 strategies
  c.client_id     = ENV['API_CLIENT_ID']
  c.client_secret = ENV['API_CLIENT_SECRET']
  c.auth_host     = 'https://auth.example.com'

  # Optional
  c.logger     = Logger.new(STDOUT)
  c.logging    = true
  c.cache_store = Rails.cache
  c.user_agent  = "My App v1"
end
```

### Navigate the API from its root

```ruby
client = Hyperlinked.client(:bearer, access_token: 'your-token-here')

root = client.root

if root.has?(:all_products)
  products = root.all_products(q: 'widgets')
  products.total_items  # => 42
  products.each do |product|
    puts product.title
    puts product.price
  end
end
```

### Iterating

Entities representing lists are fully [Enumerable](http://ruby-doc.org/core-2.2.0/Enumerable.html).

```ruby
products.each  { |p| puts p.title }
products.map(&:title)
products.reduce(0) { |sum, p| sum + p.price }
```

For paginated data sets, use `#full_set` to walk all pages automatically:

```ruby
products.full_set.each  { |p| puts p.title }
products.full_set.map(&:title)
products.full_set.first(500)
```

Check whether an entity is iterable:

```ruby
products.respond_to?(:each)
```

## Strategies

Hyperlinked supports several authentication strategies.

### 1. Authorized (token refresh via JWT assertion)

For web apps where you already have an access token. The client will automatically exchange it for a fresh one when it expires, using an OAuth2 JWT assertion flow.

```ruby
client = Hyperlinked.client(:authorized, access_token: session[:access_token]) do |new_token|
  session[:access_token] = new_token
end
```

The optional block is called with the new token whenever the old one expires — store it however you like.

### 2. Client Credentials (server-to-server / automated scripts)

Fetches an access token automatically using client credentials. Pass a stored token to skip the initial auth request.

```ruby
client = Hyperlinked.client(:client_credentials, scope: 'admin', access_token: store[:access_token]) do |new_token|
  store[:access_token] = new_token
end
```

### 3. Bearer token

Adds `Authorization: Bearer <token>` to every request. Does not handle token expiry — use this for APIs with long-lived tokens, or in tests.

```ruby
client = Hyperlinked.client(:bearer, access_token: 'your-token')
root = client.root
```

### 4. Basic Auth

Sends HTTP Basic credentials on every request.

```ruby
client = Hyperlinked.client(:basic_auth, username: 'user', password: 'secret')
root = client.root
```

## Non-GET link relations

Link metadata can specify any HTTP method. The client uses it automatically:

```ruby
client = Hyperlinked.client(:client_credentials)
root   = client.root
items  = root.items

if items.can?(:create_item)
  new_item = items.create_item(
    title: 'A new item',
    status: 'active'
  )
end

if new_item.can?(:delete_item)
  new_item.delete_item
end
```

## File / IO uploads

Anything that responds to `#read` — `File`, `StringIO`, `open-uri` results, or your own objects — is automatically base64-encoded before JSON serialization in `POST`, `PUT`, and `PATCH` requests.

```ruby
resource.upload_file(
  filename: 'photo.jpg',
  data: File.new('/path/to/photo.jpg')
)

# open-uri works too
require 'open-uri'
resource.upload_file(
  filename: 'photo.jpg',
  data: open('https://example.com/photo.jpg')
)
```

## Non-JSON responses

Responses are resolved by a configurable handler pipeline in `Hyperlinked::Configuration#response_handlers`.

Default handlers:

- `Hyperlinked::ResponseHandlers::Hal` — handles `application/json`, wraps data in `Hyperlinked::Entity`.
- `Hyperlinked::ResponseHandlers::File` — handles `image/*`, returns an IO-like object.

```ruby
# Save an image resource to disk
resource.images.each do |img|
  io = img.original
  File.open(io.file_name, 'wb') { |f| f.write io.read }
end
```

Register a custom handler (the first handler whose block returns non-nil wins):

```ruby
require 'csv'

CSVHandler = Proc.new do |resp, _client|
  if resp.headers['Content-Type'] =~ /text\/csv/
    CSV.parse(resp.body, headers: true)
  end
end

Hyperlinked.configure do |c|
  c.response_handlers.append(CSVHandler)
end

client = Hyperlinked.client(:bearer, access_token: 'abc')
csv    = client.root.some_csv_resource   # => parsed CSV
```

## CURIE / relation docs

If the API advertises CURIE link namespaces, the `docs` URL on each relation is expanded automatically:

```ruby
root.rels[:create_item].docs  # => 'https://docs.example.com/rels/create_item'
```

## Cache storage

The client honours `ETag` and `Last-Modified` HTTP caching headers. A memory store is used by default.

In Rails, plug in `Rails.cache`:

```ruby
Hyperlinked.configure do |c|
  c.cache_store = Rails.cache
end
```

Outside Rails, use the bundled Memcache wrapper (requires [Dalli](https://github.com/petergoldstein/dalli)):

```ruby
require 'hyperlinked/stores/memcache'

Hyperlinked.configure do |c|
  c.cache_store = Hyperlinked::Stores::Memcache.new(ENV['MEMCACHE_SERVER'])
end
```

## Bootstrapping from a local hash or URL

Start from a locally-defined resource without hitting the root endpoint:

```ruby
api = client.from_hash(
  '_links' => {
    'send_message'   => { 'href' => 'https://api.example.com/messages', 'method' => 'post' },
    'delete_message' => { 'href' => 'https://api.example.com/messages/{id}', 'method' => 'delete', 'templated' => true }
  }
)

msg = api.send_message(title: 'Hello')
api.delete_message(id: msg.id)
```

Or load directly from a URL:

```ruby
resource = client.from_url('https://api.example.com/some/resource')
```

## Testing

Stub chains of link relations without making real HTTP requests:

```ruby
require 'hyperlinked'

Hyperlinked.stub!

Hyperlinked.stub_chain('root.orders.first').and_return_data(
  'id'     => 42,
  'status' => 'pending'
)

client = Hyperlinked.client(:bearer, access_token: 'test')
order  = client.root.orders.first

expect(order).to be_a Hyperlinked::Entity
expect(order.status).to eq 'pending'

Hyperlinked.unstub!
```

Stubs can also match on arguments:

```ruby
Hyperlinked.stub_chain('root.orders', status: 'pending').and_return_data('count' => 3)
Hyperlinked.stub_chain('root.orders', status: 'shipped').and_return_data('count' => 7)

client.root.orders(status: 'pending').count  # => 3
client.root.orders(status: 'shipped').count  # => 7
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a Pull Request

## Release

Bump `lib/hyperlinked/version.rb` then:

```
bundle exec rake release
```
