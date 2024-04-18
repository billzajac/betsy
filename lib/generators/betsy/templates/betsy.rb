# Etsy API Key (keystring), this is the API key that you will use to access Etsy
Betsy.api_key = ENV['ETSY_API_KEY']

# Betsy this is the base URL for your application. 
# When in production it will be something like "http://www.someurl.com".
# When in development the best URL to use is "http://localhost:3000" 
# Notice: Do your url should not include "/etsy_response_listener".
Betsy.redirect_uri_base = ENV['ETSY_CALLBACK_URL_BASE']
