require 'spec_helper'

describe "stubbing" do
  before do
    Hyperlinked.stub!
  end

  after do
    Hyperlinked.unstub!
  end

  it "stubs method chains and returns entities" do
    Hyperlinked.stub_chain('root.shops.first').and_return_data({
      'name' => 'Foo bar'
    })

    client = Hyperlinked.client(:authorized, access_token: 'abc')
    shop = client.root.shops.first
    expect(shop).to be_a Hyperlinked::Entity
    expect(shop.name).to eq 'Foo bar'
  end

  it "stubs method chains and returns arrays of entities" do
    Hyperlinked.stub_chain('root.shops').and_return_data([
      {'name' => 'Foo bar'},
      {'name' => 'Bar foo'}
    ])

    client = Hyperlinked.client(:authorized, access_token: 'abc')
    shops = client.root.shops
    expect(shops.first).to be_a Hyperlinked::Entity
    expect(shops.last).to be_a Hyperlinked::Entity
    expect(shops.first.name).to eq 'Foo bar'
  end

  it 'can be chained further' do
    Hyperlinked.stub_chain('foo.bar')
    client = Hyperlinked.client(:authorized, access_token: 'abc')

    stub = client.foo.bar
    stub.stub_chain('another.stubz').and_return_data({
      'id' => 123
    })

    expect(stub.another.stubz.id).to eq 123
  end

  it 'stubs depending on arguments' do
    Hyperlinked.stub_chain('root.shops', foo: 0).and_return_data({
      'name' => 'Foo 0'
    })
    Hyperlinked.stub_chain('root.shops', foo: 1).and_return_data({
      'name' => 'Foo 1'
    })
    Hyperlinked.stub_chain('root.shops', foo: 2, bar: {yup: 'yiss'}).and_return_data({
      'name' => 'Foo 2'
    })

    client = Hyperlinked.client(:authorized, access_token: 'abc')

    expect(client.root.shops(foo: 0).name).to eq 'Foo 0'
    expect(client.root.shops(foo: 1).name).to eq 'Foo 1'
    expect(client.root.shops(foo: 2, bar: {yup: 'yiss'}).name).to eq 'Foo 2'
    # arg order shouldn't matter
    expect(client.root.shops(bar: {yup: 'yiss'}, foo: 2).name).to eq 'Foo 2'

    expect {
      client.root.shops(foo: 2, bar: {yup: 'nope'})
    }.to raise_error Hyperlinked::Stubbing::MissingStubError
  end

  it "stubs multiple chains with arguments" do
    Hyperlinked.stub_chain('one.two', arg: 1).stub_chain('three.four').and_return_data('name' => 'example 1')
    Hyperlinked.stub_chain('one.two', arg: 2).stub_chain('three.four').and_return_data('name' => 'example 2')

    client = Hyperlinked.client(:authorized, access_token: 'abc')

    expect(client.one.two(arg: 1).three.four.name).to eq 'example 1'
    expect(client.one.two(arg: 2).three.four.name).to eq 'example 2'
  end

  it "treats symbol and string keys the same" do
    Hyperlinked.stub_chain('one.two', arg: 1).and_return_data('name' => 'example 1')
    client = Hyperlinked.client(:authorized, access_token: 'abc')

    expect(client.one.two("arg" => 1).name).to eq 'example 1'
  end

  it "raises known exception if no stub found" do
    client = Hyperlinked.client(:authorized, access_token: 'abc')

    expect{
      client.nope
    }.to raise_error Hyperlinked::Stubbing::MissingStubError
  end
end
