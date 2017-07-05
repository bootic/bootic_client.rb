require 'spec_helper'

describe "stubbing" do
  before do
    BooticClient.stub!
  end

  after do
    BooticClient.unstub!
  end

  it "stubs method chains and returns entities" do
    BooticClient.stub_chain('root.shops.first').and_return_data({
      'name' => 'Foo bar'
    })

    client = BooticClient.client(:authorized, access_token: 'abc')
    shop = client.root.shops.first
    expect(shop).to be_a BooticClient::Entity
    expect(shop.name).to eq 'Foo bar'
  end

  it 'can be chained further' do
    BooticClient.stub_chain('foo.bar')
    client = BooticClient.client(:authorized, access_token: 'abc')

    stub = client.foo.bar
    stub.stub_chain('another.stubz').and_return_data({
      'id' => 123
    })

    expect(stub.another.stubz.id).to eq 123
  end

  it 'stubs depending on arguments' do
    BooticClient.stub_chain('root.shops', foo: 0).and_return_data({
      'name' => 'Foo 0'
    })
    BooticClient.stub_chain('root.shops', foo: 1).and_return_data({
      'name' => 'Foo 1'
    })
    BooticClient.stub_chain('root.shops', foo: 2, bar: {yup: 'yiss'}).and_return_data({
      'name' => 'Foo 2'
    })

    client = BooticClient.client(:authorized, access_token: 'abc')

    expect(client.root.shops(foo: 0).name).to eq 'Foo 0'
    expect(client.root.shops(foo: 1).name).to eq 'Foo 1'
    expect(client.root.shops(foo: 2, bar: {yup: 'yiss'}).name).to eq 'Foo 2'
    # arg order shouldn't matter
    expect(client.root.shops(bar: {yup: 'yiss'}, foo: 2).name).to eq 'Foo 2'

    expect {
      client.root.shops(foo: 2, bar: {yup: 'nope'})
    }.to raise_error BooticClient::Stubbing::MissingStubError
  end

  it "stubs multiple chains with arguments" do
    BooticClient.stub_chain('one.two', arg: 1).stub_chain('three.four').and_return_data('name' => 'example 1')
    BooticClient.stub_chain('one.two', arg: 2).stub_chain('three.four').and_return_data('name' => 'example 2')

    client = BooticClient.client(:authorized, access_token: 'abc')

    expect(client.one.two(arg: 1).three.four.name).to eq 'example 1'
    expect(client.one.two(arg: 2).three.four.name).to eq 'example 2'
  end

  it "treats symbol and string keys the same" do
    BooticClient.stub_chain('one.two', arg: 1).and_return_data('name' => 'example 1')
    client = BooticClient.client(:authorized, access_token: 'abc')

    expect(client.one.two("arg" => 1).name).to eq 'example 1'
  end

  it "raises known exception if no stub found" do
    client = BooticClient.client(:authorized, access_token: 'abc')

    expect{
      client.nope
    }.to raise_error BooticClient::Stubbing::MissingStubError
  end
end
