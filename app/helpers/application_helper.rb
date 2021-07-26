module ApplicationHelper
  def clerk_script_tag
    javascript_include_tag(
      "https://#{ENV.fetch('CLERK_FRONTEND_API')}/npm/@clerk/clerk-js@1/dist/clerk.browser.js",
      {
        'data-clerk-frontend-api': ENV.fetch('CLERK_FRONTEND_API'),
        crossorigin: 'anonymous',
        onload: 'startClerk()'
      }
    )
  end
end
