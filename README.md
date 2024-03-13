[![Build Status](https://travis-ci.org/bootic/bootic_client.rb.svg?branch=master)](https://travis-ci.org/bootic/bootic_client.rb)
[![Gem Version](https://badge.fury.io/rb/bootic_client.svg)](http://badge.fury.io/rb/bootic_client)


# BooticClient

Official Ruby client for the [Bootic API](https://developers.bootic.net)

## Installation

Add this line to your application's Gemfile:

    gem 'bootic_client'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install bootic_client

## Usage

### Configure with you app's credentials

You first must create an OAuth2 Application in your Bootic dashboard. Then configure the client with your `client_id` and `client_secret`.

```ruby
BooticClient.configure do |c|
  # these are required for OAuth2 strategies
  c.client_id = ENV['BOOTIC_CLIENT_ID']
  c.client_secret = ENV['BOOTIC_CLIENT_SECRET']
  # these are optional
  c.logger = Logger.new(STDOUT)
  c.logging = true
  c.cache_store = Rails.cache
  c.user_agent = "My App v1"
end
```

### Using with an existing access token

```ruby
bootic = BooticClient.client(:authorized, access_token: 'beidjbewjdiedue...')

root = bootic.root

if root.has?(:all_products)
  # All products
  all_products = root.all_products(q: 'xmas presents')
  all_products.total_items # => 23443
  all_products.each do |product|
    puts product.title
    puts product.price
  end

  # Iterate through pages of products
  # See "iterating" section below for a more elegant option
  if all_products.has?(:next)
    next_page = all_products.next
    next_page.each{...}
  end
end
```

### Iterating

Entities representing lists of things ([products](https://developers.bootic.net/rels/products/), [orders](https://developers.bootic.net/rels/orders/), etc) are fully [enumerable](http://ruby-doc.org/core-2.2.0/Enumerable.html).

```ruby
# These will only iterate this page's worth of products
all_products.each{|pr| puts pr.title}
all_products.map(&:title)
all_products.reduce(0){|sum, pr| sum + pr.price}
```

These lists might be part of a paginated data set. If you want to iterate items across pages and make sure you consume the full set, use `#full_set`.

```ruby
# These will iterate all necessary pages
all_products.full_set.each{|pr| puts pr.title }
all_products.full_set.map(&:title)
all_products.full_set.first(500)
```

You can check whether an entity is iterable with:

```ruby
all_products.respond_to?(:each)
```

## Strategies

The Bootic Client supports different authentication strategies depending on the use case.

### 1. Refresh token flow (web apps)

In this flow you first get a token by authorizing an app. ie. using [omniauth-bootic](https://github.com/bootic/omniauth-bootic)

```ruby
def client
  @client ||= BooticClient.client(:authorized, access_token: session[:access_token]) do |new_token|
    session[:access_token] = new_token
  end
end
```
Note how the client takes an optional block. This block will be called with a new access token whenever the old one expires.
It's up to your code to store this token somewhere.

### 2. User-less flow (client credentials - automated scripts)

This flow will first use your client credentials to obtain an access_token if started without one.

```ruby
client = BooticClient.client(:client_credentials, scope: 'admin', access_token: some_store[:access_token]) do |new_token|
  some_store[:access_token] = new_token
end
```

### 3. Basic Auth

This strategy uses a `username` and `password` against APIs supporting HTTP's Basic Authentication scheme.

The official Bootic API only supports OAuth2 tokens, but this allows the client to be used against internal APIs or stub APIs on development.

```ruby
client = BooticClient.client(:basic_auth, username: 'foo', password: 'bar')

root = client.root # etc
```

NOTE: `username` and `password` have nothing to do with your Bootic administrative credentials, and will be up to API maintainers to define.

### 4. Bearer token

This strategy adds an access token as a header in the format `Authorization: Bearer <your-token-here>`.
It will not try to refresh an expired token from an Oauth2 server, so there's no need to configure Oauth2 credentials.

```ruby
client = BooticClient.client(:bearer, access_token: 'foobar')

root = client.root # etc
```

Use this with APIs that don't expire tokens, or for testing.

## Non GET links

Most resource links lead to `GET` resources, but some will expect `POST`, `PUT`, `DELETE` or others.

The Bootic API encodes this information in its link metadata so the client will do the right thing. The following example creates a new product on your first shop:

```ruby
bootic = BooticClient.client(:client_credentials)

root = bootic.root

shop = root.shops.first

if shop.can?(:create_product)
  product = shop.create_product(
    title: 'A shiny new product',
    price: 122332,
    status: "visible",
    variants: [
      {
        title: 'First variant',
        sku: 'F23332-X',
        available_if_no_stock: 1,
        stock: 12
      }
    ],
    collections: [
      {title: "A new collection"},
      {id: 1234}
    ]
  )

  puts product.rels[:web].href # => 'http://acme.bootic.net/products/a-shiny-new-product'
end
```

### Working with Files and IO instances

Instances of `File`, other readable `IO` objects (and in fact anything that responds to `#read`) will be base64-encoded internally before JSON-encoding payloads for `POST`, `PUT` and `PATCH` requests.

```ruby
asset = product.create_product_asset(
  filename: 'foo.jpg',
  data: File.new('/path/to/foo.jpg') # this will base64-encode the file data in the `data` field.
)
```

Because anything that responds to `#read` will be interpreted as file data and base64-encoded, you can also pass instances of `open-uri`.

```ruby
require "open-uri"

asset = product.create_product_asset(
  filename: 'foo.jpg',
  data: open("https://some.server.com/some/image.jpg") # this will base64-encode the file data in the `data` field.
)
```

.. or even your own readers

```ruby
class MyReader
  def read
    "some data here"
  end
end

asset = product.create_product_asset(
  filename: 'foo.jpg',
  data: MyReader.new # this will base64-encode the file data in the `data` field.
)
```

## Non-JSON responses

HTTP responses are resolved by handler callables in `BooticClient::Configuration#response_handlers`.

The default stack is:

* `BooticClient::ResponseHandlers::Hal`: handles `application/json` responses and wraps JSON data in `BooticClient::Entity` instances.
* `BooticClient::ResponseHandlers::File`: handles `image/*` responses and wraps image data in IO-like objects.

```ruby
# Fetching product images and saving them to local files:
product.images.each do |img|
  io = img.original # HTTP request to image file
  # now write image data to local file.
  File.open(io.file_name, 'wb') do |f|
    f.write io.read
  end
end
```

You can register custom response handlers. The example below parses CSV response data.

```ruby
require 'csv'

# Response handlers are callable (anything that responds to #call(faraday_response, client)
# if a handler returns `nil`, the next handler in the stack will be called.
CSVHandler = Proc.new do |resp, _client|
  if resp.headers['Content-Type'] =~ /text\/csv/
    CSV.parse(resp.body, headings: true)
  end
end

BooticClient.configure do |c|
  c.response_handlers.append(CSVHandler)
end

# Now CSV resources will be returned as parsed CSV data
client = BooticClient.client(:authorized, access_token: 'abc')
root = client.root
csv = root.some_csv_resource # returns parsed CSV object.
```

## Relation docs

All resource link relations include a "docs" URL so you can learn more about that particular resource.

```ruby
shop = root.shops.first
puts shop.rels[:create_product].docs # => 'https://developers.bootic.net/rels/create_product'
```

## Cache storage

`BooticClient` honours HTTP caching headers included in API responses (such as `ETag` and `Last-Modified`).

By default a simple memory store is used. It is recommended that you use a distributed store in production, such as Memcache. In Rails applications you can use the `Rails.cache` interface.

```ruby
BooticClient.configure do |c|
  ...
  c.cache_store = Rails.cache
end
```

Outside of Rails, BooticClient ships with a wrapper around the [Dalli](https://github.com/mperham/dalli) memcache client.
You must include Dalli in your Gemfile and require the wrapper explicitely.

```ruby
require 'bootic_client/stores/memcache'
CACHE_STORE = BooticClient::Stores::Memcache.new(ENV['MEMCACHE_SERVER'])

BooticClient.configure do |c|
  ...
  c.cache_store = CACHE_STORE
end
```

## Pre-loaded or custom root resources

This client is designed to always navigate APIs starting from the root endpoint (the Hypermedia approach), but it's also possible to skip the root and start from a locally defined resource definition.

```ruby
messaging_api = client.from_hash(
  "_links" => {
    "send_message" => {"href" => 'https://some.api.com/messages', "method" => 'post'},
    "delete_message" => {"href" => 'https://some.api.com/messages/:id', "method" => 'delete', "templated" => true}
  }
)

new_message = messaging_api.send_message(title: 'This is a new message')

messaging_api.delete_message(id: new_message.id)
```

It's also possibe to load a root resource directly from a URL:

```ruby
messaging_api_root = client.from_url("https://some.api.com")
messaging_api.do_something(foo: "bar") # etc
```

## Testing

# What

This library provides methods to simplify testing. For example, to stub a chain of links you can simply do:

```rb
BooticClient.stub_chain('root.shops.first').and_return_data({
  'name' => 'Foo bar'
})

client = BooticClient.client(:authorized, access_token: 'abc')
shop = client.root.shops.first
expect(shop).to be_a BooticClient::Entity
expect(shop.name).to eq 'Foo bar'
```

You can also stub links that requires arguments, like this:

```rb
BooticClient.stub_chain('root.shops', foo: 1).and_return_data({
  'name' => 'Foo 1'
})
BooticClient.stub_chain('root.shops', foo: 1, bar: { hello: 123 }).and_return_data({
  'name' => 'Foo 2'
})

client = BooticClient.client(:authorized, access_token: 'abc')
expect(client.root.shops(foo: 1).name).to eq 'Foo 1'

# arg order doesn't matter
expect(client.root.shops(bar: { hello: 123 }, foo: 2).name).to eq 'Foo 2'
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Release

Bump version.rb and

```
bundle exec rake release
```

Update, commit and push changelog:

```
github_changelog_generator -u bootic -p bootic_client.rb
```

