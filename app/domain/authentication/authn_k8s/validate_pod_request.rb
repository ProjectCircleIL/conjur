# frozen_string_literal: true

require 'forwardable'
require 'command_class'

module Authentication
  module AuthnK8s

    ValidatePodRequest ||= CommandClass.new(
      dependencies: {
        resource_class:                      Resource,
        k8s_object_lookup_class:             K8sObjectLookup,
        validate_webservice_is_whitelisted:  ::Authentication::Security::ValidateWebserviceIsWhitelisted.new,
        validate_role_can_access_webservice: ::Authentication::Security::ValidateRoleCanAccessWebservice.new,
        enabled_authenticators:              Authentication::InstalledAuthenticators.enabled_authenticators_str(ENV),
        validate_resource_restrictions:      ValidateResourceRestrictions.new,
        extract_container_name: ExtractContainerName.new,
        logger: Rails.logger
      },
      inputs:       %i(pod_request)
    ) do

      AUTHENTICATION_CONTAINER_NAME_ANNOTATION ||= "authentication-container-name"
      DEFAULT_AUTHENTICATION_CONTAINER_NAME ||= "authenticator"

      extend Forwardable
      def_delegators :@pod_request, :service_id, :k8s_host, :spiffe_id

      def call
        validate_webservice_is_whitelisted
        validate_user_has_access_to_webservice
        validate_pod_exists
        validate_resource_restrictions
        validate_container
      end

      private

      def validate_webservice_is_whitelisted
        @validate_webservice_is_whitelisted.(
          webservice: webservice,
          account: k8s_host.account,
          enabled_authenticators: @enabled_authenticators
        )
      end

      def validate_user_has_access_to_webservice
        @validate_role_can_access_webservice.(
          webservice: webservice,
          account: k8s_host.account,
          user_id: k8s_host.k8s_host_name,
          privilege: 'authenticate'
        )
      end

      def validate_pod_exists
        unless pod
          raise Errors::Authentication::AuthnK8s::PodNotFound.new(
            pod_name,
            pod_namespace
          )
        end
      end

      def validate_resource_restrictions
        @validate_resource_restrictions.(
          host_id: k8s_host.conjur_host_id,
          host_annotations: host.annotations,
          service_id: service_id,
          account: k8s_host.account,
          spiffe_id: spiffe_id
        )
      end

      def validate_container
        unless container
          raise Errors::Authentication::AuthnK8s::ContainerNotFound,
                container_name,
                k8s_host.conjur_host_id
        end
      end

      def container
        (pod.spec.containers || []).find { |c| c.name == container_name } ||
          (pod.spec.initContainers || []).find { |c| c.name == container_name }
      end

      def container_name
        @extract_container_name.call(
          service_id: @service_id,
          host_annotations: host.annotations
        )
      end

      # @return The Conjur resource for the webservice
      def webservice
        @webservice ||= ::Authentication::Webservice.new(
          account:            k8s_host.account,
          authenticator_name: 'authn-k8s',
          service_id:         service_id
        )
      end

      def k8s_object_lookup
        @k8s_object_lookup ||= @k8s_object_lookup_class.new(webservice)
      end

      def host
        return @host if @host

        @host = @resource_class[k8s_host.conjur_host_id]
        unless @host
          raise Errors::Authentication::Security::RoleNotFound.new(
            k8s_host.conjur_host_id
          )
        end
        @host
      end

      def pod
        @pod ||= k8s_object_lookup.pod_by_name(pod_name, pod_namespace)
      end

      def pod_name
        spiffe_id.name
      end

      def pod_namespace
        spiffe_id.namespace
      end
    end
  end
end
