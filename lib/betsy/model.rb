module Betsy
  module Model
    module ClassMethods
      BASE_ETSY_API_URL = "https://openapi.etsy.com"

      def attribute(name)
        define_method name do
          @result[name.to_s]
        end
      end

      def make_request(request_type, endpoint, options = {})
        check_token_expiration(options[:etsy_account]) if options[:etsy_account]
        headers = access_credentials(options[:etsy_account])
        options.delete(:etsy_account)

        if [:post, :put, :patch].include?(request_type)
          headers = headers.reverse_merge(content_type: "application/json")
          options = options.to_json
        end

        response = Faraday.send(request_type, "#{BASE_ETSY_API_URL}#{endpoint}", options, headers)
        handle_response(response)
      end

      def check_token_expiration(etsy_account)
        if etsy_account.last_token_refresh + etsy_account.expires_in <= DateTime.now
          options = {
            grant_type: "refresh_token",
            refresh_token: etsy_account.refresh_token,
            client_id: Betsy.api_key
          }
          response = JSON.parse(Faraday.post("https://api.etsy.com/v3/public/oauth/token", options).body)
          etsy_account.access_token = response["access_token"]
          etsy_account.expires_in = response["expires_in"]
          etsy_account.refresh_token = response["refresh_token"]
          etsy_account.last_token_refresh = DateTime.now
          etsy_account.save
        end
      end

      def access_credentials(etsy_account)
        header = {x_api_key: Betsy.api_key}
        header[:Authorization] = "Bearer #{etsy_account.access_token}" if etsy_account.present?
        header
      end

      def handle_response(response)
        if response.status == 200
          return nil if response.body.empty?
          response = JSON.parse(response.body)
          build_objects(response)
        else
          Betsy::Error.new(JSON.parse(response.body).merge!("status" => response.status))
        end
      end

      def build_objects(response)
        if response["count"].nil?
          objects = new(response)
        else
          objects = []
          response["results"].each do |data|
            objects.append(new(data, response["count"]))
          end
          objects
        end
      end
    end

    # This is an ugly hack to pass response_count into each object, but I'm not sure
    # how else to do it without a massive rewrite
    attr_reader :result_count
    def initialize(data = nil, result_count = nil)
      @result = data
      @result_count = result_count
    end

    def self.included(other)
      other.extend(ClassMethods)
    end
  end
end
