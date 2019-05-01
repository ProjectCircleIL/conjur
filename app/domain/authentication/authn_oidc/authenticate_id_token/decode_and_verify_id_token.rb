require 'uri'
require 'openid_connect'
require 'authentication/errors'

module Authentication
  module AuthnOidc
    module AuthenticateIdToken

      # Possible Errors Raised:
      # IdTokenExpired, IdTokenVerifyFailed, IdTokenInvalidFormat

      DecodeAndVerifyIdToken = CommandClass.new(
        dependencies: {
          fetch_provider_certificate: ::Authentication::AuthnOidc::AuthenticateIdToken::FetchProviderCertificate.new,
          logger: Rails.logger
        },
        inputs: %i(provider_uri id_token_jwt)
      ) do

        def call
          # we fetch the certs & decode the id token here to propagate relevant errors
          fetch_certs
          decode_id_token
          verify_decoded_id_token
          decoded_attributes # return decoded attributes as hash
        end

        private

        def decode_id_token
          decoded_id_token
          @logger.debug(::LogMessages::Authentication::AuthnOidc::IDTokenDecodeSuccess.new.to_s)
        end

        def verify_decoded_id_token
          # Verify id_token expiration. OpenIDConnect requires to verify few claims.
          # Mask required claims such that effectively only expiration will be verified
          expected = { client_id: decoded_attributes[:aud] || decoded_attributes[:client_id],
                       issuer: decoded_attributes[:iss],
                       nonce: decoded_attributes[:nonce] }

          decoded_id_token.verify!(expected)
          @logger.debug(::LogMessages::Authentication::AuthnOidc::IDTokenVerificationSuccess.new.to_s)
        rescue OpenIDConnect::ResponseObject::IdToken::ExpiredToken
          raise Errors::Authentication::AuthnOidc::IdTokenExpired
        rescue => e
          raise Errors::Authentication::AuthnOidc::IdTokenVerifyFailed, e.inspect
        end

        def fetch_certs
          @certs = @fetch_provider_certificate.(provider_uri: @provider_uri)
        end

        def decoded_attributes
          @decoded_attributes ||= decoded_id_token.raw_attributes
        end

        def decoded_id_token
          @decoded_id_token ||= OpenIDConnect::ResponseObject::IdToken.decode(
            @id_token_jwt,
            @certs
          )
        rescue => e
          raise Errors::Authentication::AuthnOidc::IdTokenInvalidFormat, e.inspect
        end
      end
    end
  end
end
