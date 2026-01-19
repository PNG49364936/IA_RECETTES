# Configuration Rack::Attack pour le rate limiting
# Limite: 10 recettes par heure par IP

class Rack::Attack
  # Throttle les requêtes de création de recettes
  throttle('recipes/ip', limit: 10, period: 1.hour) do |req|
    if req.path == '/recipes' && req.post?
      req.ip
    end
  end

  # Réponse personnalisée en cas de dépassement
  self.throttled_responder = lambda do |env|
    retry_after = (env['rack.attack.match_data'] || {})[:period]

    [
      429,
      {
        'Content-Type' => 'text/html; charset=utf-8',
        'Retry-After' => retry_after.to_s
      },
      [<<~HTML
        <!DOCTYPE html>
        <html lang="fr">
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <title>Limite atteinte - Recettes IA</title>
          <style>
            body {
              font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
              background-color: #FFF8F0;
              color: #4A3728;
              display: flex;
              justify-content: center;
              align-items: center;
              min-height: 100vh;
              margin: 0;
              padding: 20px;
            }
            .container {
              text-align: center;
              max-width: 500px;
              background: white;
              padding: 40px;
              border-radius: 12px;
              box-shadow: 0 4px 20px rgba(0,0,0,0.1);
            }
            h1 {
              color: #E07B39;
              margin-bottom: 20px;
            }
            p {
              line-height: 1.6;
              margin-bottom: 20px;
            }
            a {
              display: inline-block;
              background: #E07B39;
              color: white;
              padding: 12px 24px;
              border-radius: 8px;
              text-decoration: none;
              font-weight: 600;
            }
            a:hover {
              background: #c96830;
            }
          </style>
        </head>
        <body>
          <div class="container">
            <h1>Limite atteinte</h1>
            <p>Vous avez atteint la limite de <strong>10 recettes par heure</strong>.</p>
            <p>Veuillez patienter avant de générer une nouvelle recette.</p>
            <a href="/">Retour à l'accueil</a>
          </div>
        </body>
        </html>
      HTML
      ]
    ]
  end
end

# Activer Rack::Attack dans la configuration
Rails.application.config.middleware.use Rack::Attack
