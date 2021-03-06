# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authentication::AuthnAzure::ResourceRestrictions do
  let(:test_service_id) { "MockService" }

  let(:global_annotation_type) { "authn-azure" }
  let(:granular_annotation_type) { "authn-azure/#{test_service_id}" }

  let(:user_assigned_identity_service_id_scoped_annotation) { double("UserAssignedIdentityAnnotation") }
  let(:system_assigned_identity_service_id_scoped_annotation) { double("UserAssignedIdentityServiceIdScopeAnnotation") }

  let(:subscription_id_annotation) { double("SubscriptionIdAnnotation") }
  let(:subscription_id_annotation_value) { "some-subscription-id-value" }

  let(:resource_group_annotation) { double("ResourceGroupAnnotation") }
  let(:resource_group_annotation_value) { "some-resource-group-value" }

  let(:user_assigned_identity_annotation) { double("UserAssignedIdentityAnnotation") }
  let(:user_assigned_identity_annotation_value) { "some-user-assigned-identity-value" }

  let(:system_assigned_identity_annotation) { double("SystemAssignedIdentityAnnotation") }
  let(:system_assigned_identity_annotation_value) { "some-system-assigned-identity-value" }

  let(:subscription_id_service_id_scoped_annotation) { double("SubscriptionIdServiceIdAnnotation") }
  let(:subscription_id_service_id_scoped_annotation_value) { "some-subscription-id-service-id-scoped-value" }

  let(:mismatched_subscription_id_annotation) { double("MismatchedSubscriptionIdAnnotation") }
  let(:mismatched_subscription_id_annotation_value) { "mismatched-subscription-id" }

  let(:non_azure_annotation) { double("NonAzureAnnotation") }
  let(:non_azure_annotation_value) { "some-non-azure-value" }

  def define_host_annotation(host_annotation_type:, host_annotation_key:, host_annotation_value:)
    allow(host_annotation_type).to receive(:values)
                                     .and_return(host_annotation_type)
    allow(host_annotation_type).to receive(:[])
                                     .with(:name)
                                     .and_return(host_annotation_key)
    allow(host_annotation_type).to receive(:[])
                                     .with(:value)
                                     .and_return(host_annotation_value)
  end

  before(:each) do
    define_host_annotation(
      host_annotation_type:  subscription_id_annotation,
      host_annotation_key:   "#{global_annotation_type}/subscription-id",
      host_annotation_value: subscription_id_annotation_value
    )
    define_host_annotation(
      host_annotation_type:  resource_group_annotation,
      host_annotation_key:   "#{global_annotation_type}/resource-group",
      host_annotation_value: resource_group_annotation_value
    )
    define_host_annotation(
      host_annotation_type:  user_assigned_identity_annotation,
      host_annotation_key:   "#{global_annotation_type}/user-assigned-identity",
      host_annotation_value: user_assigned_identity_annotation_value
    )
    define_host_annotation(
      host_annotation_type:  system_assigned_identity_annotation,
      host_annotation_key:   "#{global_annotation_type}/system-assigned-identity",
      host_annotation_value: system_assigned_identity_annotation_value
    )
    define_host_annotation(
      host_annotation_type:  subscription_id_service_id_scoped_annotation,
      host_annotation_key:   "#{granular_annotation_type}/subscription-id",
      host_annotation_value: subscription_id_service_id_scoped_annotation_value
    )
    define_host_annotation(
      host_annotation_type:  mismatched_subscription_id_annotation,
      host_annotation_key:   "#{global_annotation_type}/subscription-id",
      host_annotation_value: mismatched_subscription_id_annotation_value
    )
    define_host_annotation(
      host_annotation_type:  non_azure_annotation,
      host_annotation_key:   "#{global_annotation_type}/non-azure-annotation",
      host_annotation_value: "some-non-azure-value"
    )
  end

  context "Resource restrictions" do
    subject do
      Authentication::AuthnAzure::ResourceRestrictions.new(
        role_annotations: role_annotations,
        service_id:       test_service_id,
        logger:           Rails.logger
      )
    end

    context "initialize" do
      context("with a global scoped constraint") do
        context "with user-assigned-identity" do
          let(:role_annotations) {
            [
              subscription_id_annotation,
              resource_group_annotation,
              user_assigned_identity_annotation
            ]
          }

          it "does not raise an error" do
            expect { subject }.to_not raise_error
          end
          
          it "has resources with its value" do
            expect(subject.resources).to eq(
              [
                Authentication::AuthnAzure::AzureResource.new(
                  type: "subscription-id",
                  value: subscription_id_annotation_value
                ),
                Authentication::AuthnAzure::AzureResource.new(
                  type: "resource-group",
                  value: resource_group_annotation_value
                ),
                Authentication::AuthnAzure::AzureResource.new(
                  type: "user-assigned-identity",
                  value: user_assigned_identity_annotation_value
                )
              ]
            )
          end
        end

        context "with system-assigned-identity" do
          let(:role_annotations) {
            [
              subscription_id_annotation,
              resource_group_annotation,
              system_assigned_identity_annotation
            ]
          }

          it "does not raise an error" do
            expect { subject }.to_not raise_error
          end
          
          it "has resources with its value" do
            expect(subject.resources).to eq(
              [
                Authentication::AuthnAzure::AzureResource.new(
                  type: "subscription-id",
                  value: subscription_id_annotation_value
                ),
                Authentication::AuthnAzure::AzureResource.new(
                  type: "resource-group",
                  value: resource_group_annotation_value
                ),
                Authentication::AuthnAzure::AzureResource.new(
                  type: "system-assigned-identity",
                  value: system_assigned_identity_annotation_value
                )
              ]
            )
          end
        end
      end

      # it is enough to test only with subscription-id as the behavior is the same
      context("with a service-id scoped constraint") do
        context "with user-assigned-identity" do
          let(:role_annotations) {
            [
              subscription_id_service_id_scoped_annotation,
              resource_group_annotation,
              user_assigned_identity_annotation
            ]
          }

          it "does not raise an error" do
            expect { subject }.to_not raise_error
          end

          it "has resources with its value" do
            expect(subject.resources).to eq(
              [
                Authentication::AuthnAzure::AzureResource.new(
                  type: "subscription-id",
                  value: subscription_id_service_id_scoped_annotation_value
                ),
                Authentication::AuthnAzure::AzureResource.new(
                  type: "resource-group",
                  value: resource_group_annotation_value
                ),
                Authentication::AuthnAzure::AzureResource.new(
                  type: "user-assigned-identity",
                  value: user_assigned_identity_annotation_value
                )
              ]
            )
          end
        end

        context "with system-assigned-identity" do
          let(:role_annotations) {
            [
              subscription_id_service_id_scoped_annotation,
              resource_group_annotation,
              system_assigned_identity_annotation
            ]
          }

          it "does not raise an error" do
            expect { subject }.to_not raise_error
          end

          it "has resources with its value" do
            expect(subject.resources).to eq(
              [
                Authentication::AuthnAzure::AzureResource.new(
                  type: "subscription-id",
                  value: subscription_id_service_id_scoped_annotation_value
                ),
                Authentication::AuthnAzure::AzureResource.new(
                  type: "resource-group",
                  value: resource_group_annotation_value
                ),
                Authentication::AuthnAzure::AzureResource.new(
                  type: "system-assigned-identity",
                  value: system_assigned_identity_annotation_value
                )
              ]
            )
          end
        end
      end

      # Here we are only testing the scope of the subscription-id resource restriction because
      # we want to test that we grab the more granular resource restriction and the behaviour
      # is the same regardless of the annotation name
      context("with both global & service-id scoped constraints") do
        let(:role_annotations) {
          [
            subscription_id_annotation,
            subscription_id_service_id_scoped_annotation,
            resource_group_annotation
          ]
        }

        it "does not raise an error" do
          expect { subject }.to_not raise_error
        end
        
        it "has resources with its value" do
          expect(subject.resources).to eq(
            [
              Authentication::AuthnAzure::AzureResource.new(
                type: "subscription-id",
                value: subscription_id_service_id_scoped_annotation_value
              ),
              Authentication::AuthnAzure::AzureResource.new(
                type: "resource-group",
                value: resource_group_annotation_value
              )
            ]
          )
        end
      end

      context "with invalid configuration" do
        context "non permitted constraint" do
          let(:role_annotations) {
            [
              subscription_id_annotation,
              resource_group_annotation,
              user_assigned_identity_annotation,
              non_azure_annotation
            ]
          }

          it "raises an error" do
            expect { subject }.to raise_error(
              Errors::Authentication::ConstraintNotSupported
            )
          end
        end

        context "missing required constraint" do
          context "missing subscription-id constraint" do
            let(:role_annotations) {
              [
                resource_group_annotation,
                user_assigned_identity_annotation
              ]
            }

            it "raises an error" do
              expect { subject }.to raise_error(
                Errors::Authentication::RoleMissingConstraint
              )
            end
          end

          context "missing resource-group constraint" do
            let(:role_annotations) {
              [
                subscription_id_annotation,
                user_assigned_identity_annotation
              ]
            }

            it "raises an error" do
              expect { subject }.to raise_error(
                Errors::Authentication::RoleMissingConstraint
              )
            end
          end
        end

        context "non permitted constraint combinations" do
          let(:role_annotations) {
            [
              subscription_id_annotation,
              resource_group_annotation,
              user_assigned_identity_annotation,
              system_assigned_identity_annotation
            ]
          }

          it "raises an error" do
            expect { subject }.to raise_error(
              Errors::Authentication::IllegalConstraintCombinations
            )
          end
        end
      end
    end
  end
end
