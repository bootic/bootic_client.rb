[![Build Status](https://travis-ci.org/bootic/bootic_client.rb.svg?branch=master)](https://travis-ci.org/bootic/bootic_client.rb)

## WORK IN PROGRESS

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

```ruby
BooticClient.configure do |c|
  c.client_id = ENV['BOOTIC_CLIENT_ID']
  c.client_secret = ENV['BOOTIC_CLIENT_SECRET']
end
```

### Using with an existing access token

```ruby
bootic = BooticClient.client(access_token: 'beidjbewjdiedue...', logging: true)

root = bootic.root

if root.has?(:products)
  # All products
  all_products = root.products(q: 'xmas presents')
  all_products.total_items # => 23443
  all_products.each do |product|
    puts product.title
    puts product.price
  end

  if all_product.has?(:next)
    next_page = all_products.next
    next_page.each{...}
  end
end
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

