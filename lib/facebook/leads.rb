require "facebook/leads/version"
require "rest_client"

module Facebook
  module Leads
    class ResponseClient

      attr_reader :responses

      def initialize(access_token)
        @responses    = []
        @access_token = access_token
      end

      def get_form_responses(form_id)
        response  = request(url(form_id))

        process_response(response)

        while @next_link
          response = request(@next_link)
          process_response(response)
        end

        return @responses
      end

  private
      def process_response(response)
        if response.is_a? Hash
          return response
        end

        body = JSON.parse(response.body)

        @responses.concat(body["data"])

        paging     = body["paging"]
        @next_link = paging["next"]
      end

      def request(url)
        begin

          RestClient.get(url)

        rescue RestClient::Exception, Errno::ECONNREFUSED => e
          begin
            body    = JSON.parse(e.http_body)
            error   = body["error"]
            reason  = error["message"]
            fb_code = error["code"]
          rescue => p
            reason  = e.http_body
            fb_code = "-1"
          end

          return {
            :success     => false,
            :status_code => e.http_code,
            :fb_code     => fb_code,
            :reason      => reason
          }
        end
      end

      def url(form_id)
        base_url = "https://graph.facebook.com/v2.6/"
        [base_url, form_id, "/leads?access_token=", @access_token].compact.join
      end

    end
  end
end
