Clerk.configure do |c|
  c.logger = Logger.new(STDOUT) # if omitted, no logging

  # default is "https://api.clerk.dev/v1/"
  c.base_url = if Rails.env.production?
                 "https://api.clerkstage.dev/v1/"
               else
                "https://api.lclclerk.com/v1/"
               end
end
