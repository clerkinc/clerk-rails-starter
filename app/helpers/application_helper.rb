module ApplicationHelper
  def clerk_script_tag
    script_url = ENV["CLERKJS_SCRIPT_URL"].presence ||
      "https://#{ENV.fetch('CLERK_FRONTEND_API')}/npm/@clerk/clerk-js@staging/dist/clerk.browser.js"

    javascript_include_tag(
      script_url,
      {
        'data-clerk-frontend-api': ENV.fetch('CLERK_FRONTEND_API'),
        crossorigin: 'anonymous',
        onload: 'startClerk()'
      }
    )
  end
end
