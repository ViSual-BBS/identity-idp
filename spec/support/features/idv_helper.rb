module IdvHelper
  def self.included(base)
    base.class_eval { include JavascriptDriverHelper }
  end

  def max_attempts_less_one
    idv_max_attempts - 1
  end

  def idv_max_attempts
    Throttle::THROTTLE_CONFIG[:idv_resolution][:max_attempts]
  end

  def user_password
    Features::SessionHelper::VALID_PASSWORD
  end

  def fill_out_idv_form_ok
    fill_in 'profile_first_name', with: 'José'
    fill_in 'profile_last_name', with: 'One'
    fill_in 'profile_address1', with: '123 Main St'
    fill_in 'profile_city', with: 'Nowhere'
    select 'Virginia', from: 'profile_state'
    fill_in 'profile_zipcode', with: '66044'
    fill_in 'profile_dob', with: '01/02/1980'
    fill_in 'profile_ssn', with: '666-66-1234'
    find("label[for='profile_state_id_type_drivers_permit']").click
    fill_in 'profile_state_id_number', with: '123456789'
  end

  def fill_out_idv_form_fail(state: 'Virginia')
    fill_in 'profile_first_name', with: 'Bad'
    fill_in 'profile_last_name', with: 'User'
    fill_in 'profile_address1', with: '123 Main St'
    fill_in 'profile_city', with: 'Nowhere'
    select state, from: 'profile_state'
    fill_in 'profile_zipcode', with: '00000'
    fill_in 'profile_dob', with: '01/02/1900'
    fill_in 'profile_ssn', with: '666-66-6666'
    find("label[for='profile_state_id_type_drivers_permit']").click
    fill_in 'profile_state_id_number', with: '123456789'
  end

  def fill_out_idv_jurisdiction_ok
    select 'Washington', from: 'jurisdiction_state'
    page.find('label[for=jurisdiction_ial2_consent_given]').click
    expect(page).to have_no_content t('idv.errors.unsupported_jurisdiction')
  end

  def fill_out_phone_form_ok(phone = '415-555-0199')
    fill_in :idv_phone_form_phone, with: phone
  end

  def fill_out_phone_form_fail
    fill_in :idv_phone_form_phone, with: '(703) 555-5555'
  end

  def click_idv_continue
    click_on t('forms.buttons.continue')
  end

  def choose_idv_otp_delivery_method_sms
    page.find(
      'label',
      text: t('two_factor_authentication.otp_delivery_preference.sms'),
    ).click
    click_on t('idv.buttons.send_confirmation_code')
  end

  def choose_idv_otp_delivery_method_voice
    page.find(
      'label',
      text: t('two_factor_authentication.otp_delivery_preference.voice'),
    ).click
    click_on t('idv.buttons.send_confirmation_code')
  end

  def complete_idv_profile_ok(_user, password = user_password)
    fill_out_idv_form_ok
    click_idv_continue
    click_idv_continue
    click_idv_continue
    fill_in 'Password', with: password
    click_continue
  end

  def visit_idp_from_sp_with_ial2(sp)
    if sp == :saml
      settings = ial2_with_bundle_saml_settings
      settings.security[:embed_sign] = false
      if javascript_enabled?
        idp_domain_name = "#{page.server.host}:#{page.server.port}"
        settings.idp_sso_target_url = "http://#{idp_domain_name}/api/saml/auth"
        settings.idp_slo_target_url = "http://#{idp_domain_name}/api/saml/logout"
      end
      @saml_authn_request = auth_request.create(settings)
      visit @saml_authn_request
    elsif sp == :oidc
      @state = SecureRandom.hex
      @client_id = 'urn:gov:gsa:openidconnect:sp:server'
      @nonce = SecureRandom.hex
      visit_idp_from_oidc_sp_with_ial2(state: @state, client_id: @client_id, nonce: @nonce)
    end
  end

  def visit_idp_from_oidc_sp_with_ial2(state: SecureRandom.hex, client_id:, nonce:)
    visit openid_connect_authorize_path(
      client_id: client_id,
      response_type: 'code',
      acr_values: Saml::Idp::Constants::IAL2_AUTHN_CONTEXT_CLASSREF,
      scope: 'openid email profile:name phone social_security_number',
      redirect_uri: 'http://localhost:7654/auth/result',
      state: state,
      prompt: 'select_account',
      nonce: nonce,
    )
  end
end
