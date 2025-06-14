Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins %r{\Ahttp://localhost:\d+\z},
            'https://independent-fulfillment-production.up.railway.app',
            'https://widget-production-a68c.up.railway.app' # ✅ this is your frontend app
    resource '*',
      headers: :any,
      credentials: true,
      methods: [:get, :post, :put, :patch, :delete, :options, :head]
  end
end
