
Fetch
-----

Some database columns are too big in size to be downloaded. For example, there are big PDFs (~100MB) that will stop the app from functioning or kill the server.

Thus, we fetch some data from the database only when needed. We say that we put such data in the *fetch*. For us the terminologies of fetch and cache are distinguished. This is because a cache is supposed to hide something, while that's not the point for us.
