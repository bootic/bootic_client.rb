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
  c.client_id = ENV['BOOTIC_CLIENT_ID']
  c.client_secret = ENV['BOOTIC_CLIENT_SECRET']
  c.logger = Logger.new(STDOUT)
  c.logging = true
  c.cache_store = Rails.cache
end
```

### Using with an existing access token

```ruby
bootic = BooticClient.client(:authorized, access_token: 'beidjbewjdiedue...', logging: true)

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

  puts product._data.rels[:web].href # => 'http://acme.bootic.net/products/a-shiny-new-product'
end
```

## Relation docs

All resource link relations include a "docs" URL so you can learn more about that particular resource.

```ruby
shop = root.shops.first
puts shop._data.rels[:create_product].docs # => 'https://developers.bootic.net/rels/create_product'
```

## Entity#to_hash

You can get the original Hash data with

```ruby
hash = shop._data.to_hash
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

