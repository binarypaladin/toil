# Toil

## Introduction

Apparently, the Ruby world needed yet another factory gem for testing. So, here it is.

### Why not just use [insert significantly more popular factory gem here]?

This gem was built to scratch a particular itch. Some of the larger projects I test have moved away from instantiating models directly and generally use service-like objects or function modules to create new models or other resources. While the resulting object is quite often some kind of ORM model, the creation often takes a lot of virtual attributes or even takes argument signatures that are something other than a hash. I've used [Fabrication](https://www.fabricationgem.org) for years, but adapting it to my current needs didn't work out as smoothly as I would have liked.

So, here we are. I rolled my own.

### What's with the name?

Look, all the other names were gone. [Fabrication](https://www.fabricationgem.org) is already in use with a very nice website. [Machinist](https://github.com/notahat/machinist) is also taken. [factory_girl](https://github.com/thoughtbot/factory_bot) (ahem, sorry, _factory_bot_ since it got all [woke](https://thoughtbot.com/blog/factory_bot)) has a monopoly on factory_*. Even [Mike Perham](https://github.com/mperham) of [Sidekiq](https://sidekiq.org) fame is working on [Faktory](https://github.com/contribsys/faktory)—and while it has nothing to do with tests, I don't even have the obvious rename-with-a-wrong-spelling option out there without confusing people. I guess I could have gone with like Factori, Factoree, or like... never mind. Those clearly suck. Even Sweatshop, the original name, was taken.

Tests are a toil. It's four letters. It was available.

### Design Goals

I use [Fabrication](https://www.fabricationgem.org) without any nesting to generate attributes. That's about it. Those attributes are then passed to service objects to make stuff. This means generating attributes doesn't have to know anything about dependencies. This works okay until:

1. You're working with something other than hashes.
2. You go to modify/extend your existing factory gem and realize it's not exactly the right tool for the job.

I wanted a very small, simple codebase. This is really just a container for potentially dynamic attribute generation and methods for spitting out dependencies for tests. I also wanted a codebase that doesn't really care about what it's building. Whether you're using [Sequel](https://github.com/jeremyevans/sequel), [ActiveRecord](https://github.com/rails/rails/tree/master/activerecord), [ROM](https://rom-rb.org), or something that doesn't touch a database, it doesn't matter.

This generates arguments, passes them to some sort of constructor or creator object (it's just got to respond to `call`), processes a few optional callbacks, and spits out your object. Simple, repetitive, and mind-numbing—sound familiar?

## Installation

Pretty standard gem stuff.

```
$ gem install toil
```

If you're using [Bundler](https://bundler.io) (and who isn't?) it's likely you'll add this to the `:test` group of your `Gemfile` like so:

```
group :test do
  gem 'toil'
end
```

Maybe include it in `:development` too. Whatever. You be you.

## Usage

While one of the primary goals is dealing with an array of arguments, a hash of attributes still works just as naturally and a lot of the DSL is very much biased in that direction.

These examples will use [Faker](https://github.com/stympy/faker).

### Registration

Register a new prototype like so:

```ruby
Toil.register(:person, ->(*args) { Person.create(*args) }) do
  name { Faker::Name.name }
end
```

The second argument must respond to `call`, so a `proc` or `lambda` will work fine in instances where you have no constructor object.

You can duplicate and extend existing prototypes passing a `Symbol`:

```ruby
Toil.register(:star_wars_character, :person) do
  name { Faker::StarWars.character }
end
```
### Arguments vs. Attributes

The DSL is quite opinionated toward a single argument attribute hash. All the DSL methods effect the first hash in the arguments list. This means if you have two hashes, you'll have to make changes to the second in a more "manual" fashion.

The `arg` and `arg_at` methods can be used to add or insert arguments when creating or duplicating a prototype. Overrides also account arrays to override arguments.

It can get really complicated when duplicating factories. There's little reason to abuse this. An extremely common pattern is:

`CreatorClass.call(object1, object2, attributes)`

Basically, you have some related dependencies that don't get added as attributes (or maybe the attributes are optional). Whatever the case, these options exist to satisfy constructors that don't just take a hash of options.

### Callbacks

There are only two callbacks, `before_create` and `after_create`. Each time the method is invoked, a new callback is added to each stack. So, if you're duplicating an existing prototype, keep in mind you'll be adding more callbacks, not replacing existing ones.

#### `before_create`

This is meant to transform arguments being passed to the constructor in some way that requires context from existing arguments. A simple example would be that you wanted to create an email address from a randomly generated name.

```ruby
Toil.register(:person_with_email, :person) do
  before_create do |attributes, *|
    attributes[:email] = Faker::Internet.email(attributes[:name])
  end
end
```

Note: Arguments are passed as a single array, since you may want to mutate any possible arguments. If you plan on having a single attributes hash, remember to append your method with a splat like the example above.

#### `after_create`

The object created once attributes are passed to the constructor will always be yielded to `after_create`. Unlike `before_create` you don't have to pay any attention to what is returned. The same object will be yielded to every `after_create` callback. This is generally for adding relationships or processing state transitions on an object. For example:

```ruby
Toil.register(:pending_order, OrderCreator) do
  # ...
end

Toil.register(:paid_order, :pending_order) do
  after_create { |order| OrderPayer.call(order, amount: order.full_amount) }
end
```

### What about relationships?

You don't use nested attributes or arguments to build relationships. Dependencies and related resources should be created with other prototypes either as arguments or in `after_create` hooks. For example:

```ruby
Toil.register(:album, AlbumCreator)

Toil.register(:rio_album, :album) do
  artist { Toil.create(:duran_duran) }
  tracks 9
  release_date Date.new(1982, 5, 10)
end

Toil.register(:rio_album_multiplatinum, :rio_album) do
  after_create do |obj|
    2_000_000.times { Toil.create(:album_sale, album: obj) }
  end
end

```

### Creating Objects

Use `create` to try and create an object of some sort. You pass in overrides, either as a hash or an array (it gets splatted). You can use this to add more arguments, or override defaults:

```ruby
Toil.create(:star_wars_character, name: 'James T. Kirk')
```

Overrides are resolved first, so if your prototypes create dependencies, they **will not** be created in addition to whatever override is passed in.

## Contributing

### Issue Guidelines

GitHub issues are for bugs, not support. As of right now, there is no official support for this gem. You can try reaching out to the author, [Joshua Hansen](mailto:joshua@epicbanality.com?subject=Toil+sucks) if you're really stuck, but there's a pretty high chance that won't go anywhere at the moment or you'll get a response like this:

> Hi. I'm super busy. It's nothing personal. Check the README first if you haven't already. If you don't find your answer there, it's time to start reading the source. Have fun! Let me know if I screwed something up.

### Pull Request Guidelines

* Include tests with your PRs.
* Run `bundle exec rubocop` to ensure your style fits with the rest of the project.

### Code of Conduct

Sorry, I'm not woke.

## License

See [`LICENSE.txt`](LICENSE.txt).

## What if I stop maintaining this?

The codebase is pretty small. That was one of the main design goals. If you can figure out how to use it, I'm sure you can maintain it.
