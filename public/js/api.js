function Api() {
  const self = Object.create(null)

  self.csrf = () => document.querySelector('meta[name="_csrf"]').content

  self.request = (method, url, body) => {
    return fetch(url, {
      method,
      headers: {
        "X-CSRF-Token": self.csrf(),
        ...(body ? {"Content-Type": "application/json"} : {})
      },
      body: body ? JSON.stringify(body) : undefined
    })
  }

  return self
}

export { Api }
