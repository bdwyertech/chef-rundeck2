# Chef-RunDeck

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/chef-rundeck`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Background
This project started out to act as a proxy for administrative Chef Server interactions, namely client/node deletion.

If you are familiar with Chef & Terraform, you are likely aware that Terraform currently does not remove the client/node pair from the Chef server upon destruction.  Additionally, you are likely aware that deletion of client/node objects requires elevated privileges on the Chef server; privileges that the validation client does not provide.
To work around this, one might use `knife` configured with administrative client.  When combined with RunDeck, the security outlook does not look good as one might easily run a `cat` on the PEM file from the Command interface, allowing them to view the credential.  Unless otherwise orchestrated, any/all local commands will run under the context of the RunDeck user, likely the same user with ownership of said PEM file, so using `knife` under the RunDeck context is inherently insecure if the RunDeck is used for other things and/or the Command interface is exposed.

The idea here is to run this Gem under a different user's context, proxying administrative commands via simple GET/POST requests.  The administrative PEM is then owned by a seperate user, preventing one from easily accessing it.  Additionally, a simple `state` endpoint can be used to maintain an audit trail of who created what node, and allow said user to then delete the node.  Deletion is limited to only member nodes of the `state`, and only by the original creator, unless the user is an administrator.  The security here is rather primitive, as the user is passed in as a query parameter, but better than nothing.  I had the idea of combining this with a sort of API key unique to the user, but have yet to implement it.  The limitation of only deleting nodes belonging to the current `state` is the current stop gap.  Also, this means if you have existing nodes, you'll likely want to populate your `state` file with them.  A sample state object is available at `config/state.json`.

**NOTE:** This API should **NOT** be exposed to the world unless you plan to secure it with a reverse-proxy or something.  It is intended to only be bound to `localhost` on the same server as RunDeck.

## RunDeck Options Provider
This gem also serves as a RunDeck options provider, delivering node search results in the RunDeck `RESOURCE-JSON` format.
* This project **ONLY** uses partial search.  You can add additional values to the search filter with the `extras` param (comma-separated) or inside project-specific config (Array).
* The search/return is customizable, either by passing query parameters, or by creating project-specific configuration and hitting the project endpoint.
* Query parameters will overrule project-specific configuration.
* You don't have to pass in a user, granting the ability to set that sort of configuration in the RunDeck project configuration.

## Running as a Service
You'll likely want to run this as a service, `SystemD` or `Upstart` will likely be your friend in this regard.

## Security
You should lock down permissions on all configuration files in this project to only the user which this runs as...

To run this project securely, **DON'T** run it as the RunDeck user. 

## Caching
This leans on `rack-cache` to serve as a caching mechanism.  The objective here was to make sure we don't pummel the Chef API with redundant queries.

## Credits
This Gem leans heavily on Seth Vargo's `ChefAPI` gem.  I also took many ideas from his Gem to build this one, as I've never written anything like this before.  Thank you, Seth, for both the `ChefAPI` gem and for your consistent high quality contributions to the DevOps community.

Also, thank you to Adam Jacob for initially developing the `chef-rundeck` gem which served as a baseline for building the Options Provider portion of this one. Thanks for Chef, you've greatly reduce the amount of chaos in my work life!


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'chef-rundeck'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install chef-rundeck

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/bdwyertech/chef-rundeck. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

