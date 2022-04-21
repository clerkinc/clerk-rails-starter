# The following module monkey-patches the original Clerk::RackMiddlewareV2
# implementation so as to skip running the middleware in specific routes.
#
# Use it with `Clerk::RackMiddlewareV2.prepend ClerkExtensions`
module ClerkExtensions
  def call(env)
    req = Rack::Request.new(env)

    if req.path.starts_with?("/some-non-clerk-url")
      @app.call(env) # skips Clerk middleware
    else
      super
    end
  end
end
