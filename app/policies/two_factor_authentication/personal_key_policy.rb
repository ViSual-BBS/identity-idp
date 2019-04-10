module TwoFactorAuthentication
  class PersonalKeyPolicy
    def initialize(user)
      @user = user
    end

    def configured?
      user&.encrypted_recovery_code_digest.present?
    end

    def enabled?
      configured?
    end

    def visible?
      !FeatureManagement.personal_key_assignment_disabled?
    end

    private

    attr_reader :user
  end
end
