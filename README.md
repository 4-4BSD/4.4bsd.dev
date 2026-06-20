## About

The source code for [4.4bsd.dev](https://4.4bsd.dev).

This project provides the
[FreeBSD documentation repository](https://cgit.freebsd.org/doc)
as a SQLite3 database that can be queried with FTS through a headless
web interface that scripts can easily interact with. This project
began as a way to provide [robert](https://github.com/4-4BSD/robert)
with access to the FreeBSD handbook and has since evolved to cover
**multiple books**: the user's handbook, the developer's handbook, and
the porter's handbook. More might follow.

## Usage

### Requirements

#### Repository

A copy of the [FreeBSD documentation repository](https://cgit.freebsd.org/doc) is required. <br>
By default it is expected to be found at `../doc` although you can
customize the location by setting the environment variable `${DOC_REPO}`.

### CLI

#### create-database

Creates a new database in `share/handbook/database.sqlite3`

    $ handbook create-database

#### web

Serves a HTTP API that can query the handbook with FTS

    $ handbook web
    $ fetch 'http://localhost:9292?q=ports'

### Library

#### Repository

The Repository, Book, Chapter, and Section classes
provide the handbook to a Ruby runtime:

```ruby
r = Repository.new(locale: "en")
r.books.each do |book|
  print "The book ", book.name, " has #{book.chapters.size} chapters"
end
```

## License

0BSD.
See [LICENSE](./LICENSE)