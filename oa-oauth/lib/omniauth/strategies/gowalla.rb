require 'omniauth/oauth'
require 'multi_json'

module OmniAuth
  module Strategies
    #
    # Authenticate to Gowalla utilizing OAuth 2.0 and retrieve
    # basic user information.
    #
    # Usage:
    #
    #    use OmniAuth::Strategies::Gowalla, 'API Key', 'Secret Key'
    #
    # Options:
    #
    # <tt>:scope</tt> :: Extended permissions such as <tt>email</tt> and <tt>offline_access</tt> (which are the defaults).
    class Gowalla < OAuth2
      def initialize(app, api_key, secret_key, options = {})
        options[:site] = 'https://api.gowalla.com/api/oauth'
        options[:authorize_url] = 'https://gowalla.com/api/oauth/new'
        options[:access_token_url] = 'https://api.gowalla.com/api/oauth/token'
        super(app, :gowalla, api_key, secret_key, options)
      end
      
      def user_data
        @data ||= MultiJson.decode(@access_token.get("/users/me.json"))
      end
      
      def request_phase(options = {})
        options[:scope] ||= "email,offline_access"
        super(options)
      end
      
      def user_info
        {
          'name' => "#{user_data['first_name']} #{user_data['last_name']}",
          'nickname' => user_data["username"],
          'first_name' => user_data["first_name"],
          'last_name' => user_data["last_name"],
          'location' => user_data["hometown"],
          'description' => user_data["bio"],
          'image' => user_data["image_url"],
          'phone' => nil,
          'urls' => {
            'Gowalla' => "http://www.gowalla.com#{user_data['url']}",
            'Website' => user_data["website"]
          }
        }
      end
      
      def auth_hash
        OmniAuth::Utils.deep_merge(super, {
          'uid' => user_data["url"].split('/').last,
          'user_info' => user_info,
          'extra' => {'user_hash' => user_data}
        })
      end
    end
  end
end
