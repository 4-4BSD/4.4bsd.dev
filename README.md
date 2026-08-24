<p align="center">
  <a href="https://4.4bsd.dev">
    <img
      src="public/images/44bsd-workmark.svg"
      width="400"
      height="200"
      border="0"
      alt="a 4.4bsd.dev project"
     >
  </a>
</p>

> A [4.4bsd.dev](https://4.4bsd.dev) project.

Welcome to the 4.4bsd.dev website.

4.4bsd.dev is the home of a FreeBSD chatbot that answers questions using
the live documentation and package repositories on a FreeBSD system. It
can read manual pages with man(1), search them with apropos(1), and search
remote packages with pkg-search(8). Its answers are grounded in those
official sources rather than training data.

The chatbot is an [llm.rb](https://github.com/r-uby-dev/llm) agent. It is
backed by an ActiveRecord model that uses `acts_as_agent` and each visitor's
session is serialized into a single database column. Responses stream to the
browser with the
[roda-sse](https://github.com/havenwood/roda-sse) plugin on top of the
[Roda](https://github.com/jeremyevans/roda) web toolkit.

## License

This software is released under the terms of the MIT license. <br>
See [LICENSE](./LICENSE) for details.
