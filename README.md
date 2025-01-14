# Chronomancer

Chronomancer is a simple library for creating modifyable date sequences in Ruby.

## Installation

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add chronomancer
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install chronomancer
```

## Concepts

Chronomancer has two main concepts. A `Sequence` and a `Recurrence`.

A `Recurrence` is just some rule for recurrence, like "every 3 months".

A `Sequence` is a `Recurrence` that can be configured and retains it's history after
reconfiguration.

```rb
sequence = Chronomancer::Sequence.monthly.starting(Time.current + 5.days).total(15)

sequence.pause(Chronomancer::Recurrence.daily(Time.current + 18.days).total(45))
sequence.reconfigure(interval: 2.months)

sequence.to_a
```

## Usage

Chronomancer allows you to easily create sequences through the builder pattern:

```rb
s = Chronomancer.monthly.starting(Time.current + 5.days).total(15)
```

Every `Chronomancer::Sequence` and `Chronomancer::Recurrence` implements `Enumerable`.

So things like the following just work as expected.

```rb
s.take(10)
s.first
s.last
# etc
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/MSILycanthropy/chronomancer. This project is intended to be a safe, welcoming space for collaboration.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

