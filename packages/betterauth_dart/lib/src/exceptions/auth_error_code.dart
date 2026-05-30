/// {@template auth_error_code}
/// Stable, machine-readable error identifiers returned by a better-auth server
/// in the `code` field of an error response body (`{ "message", "code" }`).
///
/// Use [AuthErrorCode.fromWire] to map a wire string to a value, and switch on
/// `AuthException.code` to handle specific failures. Any code not recognised
/// here (including codes from plugins this SDK does not model) maps to
/// [AuthErrorCode.unknown]; the raw string remains available via
/// `AuthException.rawCode`.
/// {@endtemplate}
enum AuthErrorCode {
  // --- Core (BASE_ERROR_CODES) ---
  /// The requested user does not exist.
  userNotFound('USER_NOT_FOUND'),

  /// The server failed to create the user.
  failedToCreateUser('FAILED_TO_CREATE_USER'),

  /// The server failed to create a session.
  failedToCreateSession('FAILED_TO_CREATE_SESSION'),

  /// The server failed to update the user.
  failedToUpdateUser('FAILED_TO_UPDATE_USER'),

  /// The server failed to read the session.
  failedToGetSession('FAILED_TO_GET_SESSION'),

  /// The supplied password is invalid.
  invalidPassword('INVALID_PASSWORD'),

  /// The supplied email is invalid.
  invalidEmail('INVALID_EMAIL'),

  /// The email/password combination is invalid.
  invalidEmailOrPassword('INVALID_EMAIL_OR_PASSWORD'),

  /// The user reference is invalid.
  invalidUser('INVALID_USER'),

  /// The social account is already linked to another user.
  socialAccountAlreadyLinked('SOCIAL_ACCOUNT_ALREADY_LINKED'),

  /// The requested OAuth provider is not configured.
  providerNotFound('PROVIDER_NOT_FOUND'),

  /// The supplied token is invalid.
  invalidToken('INVALID_TOKEN'),

  /// The supplied token has expired.
  tokenExpired('TOKEN_EXPIRED'),

  /// ID-token sign-in is not supported for this provider.
  idTokenNotSupported('ID_TOKEN_NOT_SUPPORTED'),

  /// The server failed to fetch user info from the provider.
  failedToGetUserInfo('FAILED_TO_GET_USER_INFO'),

  /// No email was found for the user.
  userEmailNotFound('USER_EMAIL_NOT_FOUND'),

  /// The email address has not been verified.
  emailNotVerified('EMAIL_NOT_VERIFIED'),

  /// The password is shorter than the configured minimum.
  passwordTooShort('PASSWORD_TOO_SHORT'),

  /// The password is longer than the configured maximum.
  passwordTooLong('PASSWORD_TOO_LONG'),

  /// A user with these details already exists.
  userAlreadyExists('USER_ALREADY_EXISTS'),

  /// A user already exists; a different email must be used.
  userAlreadyExistsUseAnotherEmail('USER_ALREADY_EXISTS_USE_ANOTHER_EMAIL'),

  /// The email address cannot be updated.
  emailCanNotBeUpdated('EMAIL_CAN_NOT_BE_UPDATED'),

  /// Changing email is disabled on the server.
  changeEmailDisabled('CHANGE_EMAIL_DISABLED'),

  /// No credential (password) account was found for the user.
  credentialAccountNotFound('CREDENTIAL_ACCOUNT_NOT_FOUND'),

  /// The session has expired.
  sessionExpired('SESSION_EXPIRED'),

  /// The last remaining account cannot be unlinked.
  failedToUnlinkLastAccount('FAILED_TO_UNLINK_LAST_ACCOUNT'),

  /// The requested account does not exist.
  accountNotFound('ACCOUNT_NOT_FOUND'),

  /// The user already has a password set.
  userAlreadyHasPassword('USER_ALREADY_HAS_PASSWORD'),

  /// Login was blocked due to cross-site navigation.
  crossSiteNavigationLoginBlocked('CROSS_SITE_NAVIGATION_LOGIN_BLOCKED'),

  /// Verification email sending is not enabled.
  verificationEmailNotEnabled('VERIFICATION_EMAIL_NOT_ENABLED'),

  /// The email address is already verified.
  emailAlreadyVerified('EMAIL_ALREADY_VERIFIED'),

  /// The provided email does not match the expected one.
  emailMismatch('EMAIL_MISMATCH'),

  /// The session is not fresh enough for this operation.
  sessionNotFresh('SESSION_NOT_FRESH'),

  /// The linked account already exists.
  linkedAccountAlreadyExists('LINKED_ACCOUNT_ALREADY_EXISTS'),

  /// The request origin is invalid.
  invalidOrigin('INVALID_ORIGIN'),

  /// The callback URL is invalid.
  invalidCallbackUrl('INVALID_CALLBACK_URL'),

  /// The redirect URL is invalid.
  invalidRedirectUrl('INVALID_REDIRECT_URL'),

  /// The error callback URL is invalid.
  invalidErrorCallbackUrl('INVALID_ERROR_CALLBACK_URL'),

  /// The new-user callback URL is invalid.
  invalidNewUserCallbackUrl('INVALID_NEW_USER_CALLBACK_URL'),

  /// The request is missing or has a null origin.
  missingOrNullOrigin('MISSING_OR_NULL_ORIGIN'),

  /// A callback URL is required for this operation.
  callbackUrlRequired('CALLBACK_URL_REQUIRED'),

  /// The server failed to create a verification record.
  failedToCreateVerification('FAILED_TO_CREATE_VERIFICATION'),

  /// A submitted field is not allowed.
  fieldNotAllowed('FIELD_NOT_ALLOWED'),

  /// Async validation is not supported here.
  asyncValidationNotSupported('ASYNC_VALIDATION_NOT_SUPPORTED'),

  /// A validation error occurred.
  validationError('VALIDATION_ERROR'),

  /// A required field is missing.
  missingField('MISSING_FIELD'),

  /// POST `/get-session` requires `deferSessionRefresh` to be enabled.
  methodNotAllowedDeferSessionRequired(
    'METHOD_NOT_ALLOWED_DEFER_SESSION_REQUIRED',
  ),

  /// The request body must be a JSON object.
  bodyMustBeAnObject('BODY_MUST_BE_AN_OBJECT'),

  /// A password has already been set.
  passwordAlreadySet('PASSWORD_ALREADY_SET'),

  // --- Email OTP plugin ---
  /// The one-time password has expired.
  otpExpired('OTP_EXPIRED'),

  /// The one-time password is invalid.
  invalidOtp('INVALID_OTP'),

  /// Too many attempts were made.
  tooManyAttempts('TOO_MANY_ATTEMPTS'),

  // --- Phone number plugin ---
  /// The phone number is invalid.
  invalidPhoneNumber('INVALID_PHONE_NUMBER'),

  /// The phone number already exists.
  phoneNumberExist('PHONE_NUMBER_EXIST'),

  /// The phone number does not exist.
  phoneNumberNotExist('PHONE_NUMBER_NOT_EXIST'),

  /// The phone-number/password combination is invalid.
  invalidPhoneNumberOrPassword('INVALID_PHONE_NUMBER_OR_PASSWORD'),

  /// An unexpected error occurred.
  unexpectedError('UNEXPECTED_ERROR'),

  /// No OTP was found.
  otpNotFound('OTP_NOT_FOUND'),

  /// The phone number is not verified.
  phoneNumberNotVerified('PHONE_NUMBER_NOT_VERIFIED'),

  /// The phone number cannot be updated.
  phoneNumberCannotBeUpdated('PHONE_NUMBER_CANNOT_BE_UPDATED'),

  /// The server has no `sendOTP` implementation configured.
  sendOtpNotImplemented('SEND_OTP_NOT_IMPLEMENTED'),

  // --- Username plugin ---
  /// The username/password combination is invalid.
  invalidUsernameOrPassword('INVALID_USERNAME_OR_PASSWORD'),

  /// The username is already taken.
  usernameIsAlreadyTaken('USERNAME_IS_ALREADY_TAKEN'),

  /// The username is shorter than the configured minimum.
  usernameTooShort('USERNAME_TOO_SHORT'),

  /// The username is longer than the configured maximum.
  usernameTooLong('USERNAME_TOO_LONG'),

  /// The username is invalid.
  invalidUsername('INVALID_USERNAME'),

  /// The display username is invalid.
  invalidDisplayUsername('INVALID_DISPLAY_USERNAME'),

  // --- Two factor plugin ---
  /// OTP-based two-factor is not enabled.
  otpNotEnabled('OTP_NOT_ENABLED'),

  /// The two-factor OTP has expired.
  otpHasExpired('OTP_HAS_EXPIRED'),

  /// TOTP-based two-factor is not enabled.
  totpNotEnabled('TOTP_NOT_ENABLED'),

  /// Two-factor authentication is not enabled.
  twoFactorNotEnabled('TWO_FACTOR_NOT_ENABLED'),

  /// Backup codes are not enabled.
  backupCodesNotEnabled('BACKUP_CODES_NOT_ENABLED'),

  /// The supplied backup code is invalid.
  invalidBackupCode('INVALID_BACKUP_CODE'),

  /// The supplied verification code is invalid.
  invalidCode('INVALID_CODE'),

  /// Too many attempts were made; a new code must be requested.
  tooManyAttemptsRequestNewCode('TOO_MANY_ATTEMPTS_REQUEST_NEW_CODE'),

  /// The two-factor challenge cookie is missing or invalid.
  invalidTwoFactorCookie('INVALID_TWO_FACTOR_COOKIE'),

  // --- Anonymous plugin ---
  /// The current session user is not an anonymous user.
  userIsNotAnonymous('USER_IS_NOT_ANONYMOUS'),

  /// Deleting anonymous users is disabled on the server.
  deleteAnonymousUserDisabled('DELETE_ANONYMOUS_USER_DISABLED'),

  /// The server failed to delete the anonymous user.
  failedToDeleteAnonymousUser('FAILED_TO_DELETE_ANONYMOUS_USER'),

  // --- Passkey plugin ---
  /// The passkey challenge was not found or has expired.
  challengeNotFound('CHALLENGE_NOT_FOUND'),

  /// The requested passkey does not exist.
  passkeyNotFound('PASSKEY_NOT_FOUND'),

  /// The server failed to verify the passkey registration.
  failedToVerifyRegistration('FAILED_TO_VERIFY_REGISTRATION'),

  /// The server failed to verify the passkey authentication.
  failedToVerifyAuthentication('FAILED_TO_VERIFY_AUTHENTICATION'),

  // --- Organization plugin: organization ---
  /// You are not allowed to create a new organization.
  youAreNotAllowedToCreateANewOrganization(
    'YOU_ARE_NOT_ALLOWED_TO_CREATE_A_NEW_ORGANIZATION',
  ),

  /// You have reached the maximum number of organizations.
  youHaveReachedTheMaximumNumberOfOrganizations(
    'YOU_HAVE_REACHED_THE_MAXIMUM_NUMBER_OF_ORGANIZATIONS',
  ),

  /// The organization already exists.
  organizationAlreadyExists('ORGANIZATION_ALREADY_EXISTS'),

  /// The organization slug is already taken.
  organizationSlugAlreadyTaken('ORGANIZATION_SLUG_ALREADY_TAKEN'),

  /// The organization does not exist.
  organizationNotFound('ORGANIZATION_NOT_FOUND'),

  /// You are not allowed to update this organization.
  youAreNotAllowedToUpdateThisOrganization(
    'YOU_ARE_NOT_ALLOWED_TO_UPDATE_THIS_ORGANIZATION',
  ),

  /// You are not allowed to delete this organization.
  youAreNotAllowedToDeleteThisOrganization(
    'YOU_ARE_NOT_ALLOWED_TO_DELETE_THIS_ORGANIZATION',
  ),

  /// There is no active organization in the current session.
  noActiveOrganization('NO_ACTIVE_ORGANIZATION'),

  // --- Organization plugin: members ---
  /// The user is not a member of the organization.
  userIsNotAMemberOfTheOrganization(
    'USER_IS_NOT_A_MEMBER_OF_THE_ORGANIZATION',
  ),

  /// The member does not exist.
  memberNotFound('MEMBER_NOT_FOUND'),

  /// The user is already a member of this organization.
  userIsAlreadyAMemberOfThisOrganization(
    'USER_IS_ALREADY_A_MEMBER_OF_THIS_ORGANIZATION',
  ),

  /// You are not allowed to delete this member.
  youAreNotAllowedToDeleteThisMember(
    'YOU_ARE_NOT_ALLOWED_TO_DELETE_THIS_MEMBER',
  ),

  /// You are not allowed to update this member.
  youAreNotAllowedToUpdateThisMember(
    'YOU_ARE_NOT_ALLOWED_TO_UPDATE_THIS_MEMBER',
  ),

  /// The organization membership limit has been reached.
  organizationMembershipLimitReached('ORGANIZATION_MEMBERSHIP_LIMIT_REACHED'),

  /// You cannot leave the organization as the only owner.
  youCannotLeaveTheOrganizationAsTheOnlyOwner(
    'YOU_CANNOT_LEAVE_THE_ORGANIZATION_AS_THE_ONLY_OWNER',
  ),

  /// You cannot leave the organization without an owner.
  youCannotLeaveTheOrganizationWithoutAnOwner(
    'YOU_CANNOT_LEAVE_THE_ORGANIZATION_WITHOUT_AN_OWNER',
  ),

  /// The requested role does not exist.
  roleNotFound('ROLE_NOT_FOUND'),

  // --- Organization plugin: invitations ---
  /// You are not allowed to invite users to this organization.
  youAreNotAllowedToInviteUsersToThisOrganization(
    'YOU_ARE_NOT_ALLOWED_TO_INVITE_USERS_TO_THIS_ORGANIZATION',
  ),

  /// The user is already invited to this organization.
  userIsAlreadyInvitedToThisOrganization(
    'USER_IS_ALREADY_INVITED_TO_THIS_ORGANIZATION',
  ),

  /// The invitation does not exist.
  invitationNotFound('INVITATION_NOT_FOUND'),

  /// You are not the recipient of the invitation.
  youAreNotTheRecipientOfTheInvitation(
    'YOU_ARE_NOT_THE_RECIPIENT_OF_THE_INVITATION',
  ),

  /// You are not allowed to cancel this invitation.
  youAreNotAllowedToCancelThisInvitation(
    'YOU_ARE_NOT_ALLOWED_TO_CANCEL_THIS_INVITATION',
  ),

  /// The inviter is no longer a member of the organization.
  inviterIsNoLongerAMemberOfTheOrganization(
    'INVITER_IS_NO_LONGER_A_MEMBER_OF_THE_ORGANIZATION',
  ),

  /// You are not allowed to invite a user with this role.
  youAreNotAllowedToInviteUserWithThisRole(
    'YOU_ARE_NOT_ALLOWED_TO_INVITE_USER_WITH_THIS_ROLE',
  ),

  /// The invitation limit has been reached.
  invitationLimitReached('INVITATION_LIMIT_REACHED'),

  /// Email verification is required before accepting or rejecting an invite.
  emailVerificationRequiredBeforeAcceptingOrRejectingInvitation(
    'EMAIL_VERIFICATION_REQUIRED_BEFORE_ACCEPTING_OR_REJECTING_INVITATION',
  ),

  // --- Organization plugin: teams ---
  /// You are not allowed to create a new team.
  youAreNotAllowedToCreateANewTeam('YOU_ARE_NOT_ALLOWED_TO_CREATE_A_NEW_TEAM'),

  /// The team already exists.
  teamAlreadyExists('TEAM_ALREADY_EXISTS'),

  /// The team does not exist.
  teamNotFound('TEAM_NOT_FOUND'),

  /// You have reached the maximum number of teams.
  youHaveReachedTheMaximumNumberOfTeams(
    'YOU_HAVE_REACHED_THE_MAXIMUM_NUMBER_OF_TEAMS',
  ),

  /// The last team cannot be removed.
  unableToRemoveLastTeam('UNABLE_TO_REMOVE_LAST_TEAM'),

  /// You are not allowed to delete this team.
  youAreNotAllowedToDeleteThisTeam('YOU_ARE_NOT_ALLOWED_TO_DELETE_THIS_TEAM'),

  /// You are not allowed to update this team.
  youAreNotAllowedToUpdateThisTeam('YOU_ARE_NOT_ALLOWED_TO_UPDATE_THIS_TEAM'),

  /// The team member limit has been reached.
  teamMemberLimitReached('TEAM_MEMBER_LIMIT_REACHED'),

  /// The user is not a member of the team.
  userIsNotAMemberOfTheTeam('USER_IS_NOT_A_MEMBER_OF_THE_TEAM'),

  /// You do not have an active team.
  youDoNotHaveAnActiveTeam('YOU_DO_NOT_HAVE_AN_ACTIVE_TEAM'),

  // --- Inline / ad-hoc ---
  /// An error occurred while linking an OAuth account.
  oauthLinkError('OAUTH_LINK_ERROR'),

  /// Email/password authentication is disabled on the server.
  emailPasswordDisabled('EMAIL_PASSWORD_DISABLED'),

  /// An unrecognised code, including codes from plugins this SDK does not
  /// model. The raw value is preserved on `AuthException.rawCode`.
  unknown('UNKNOWN')
  ;

  const AuthErrorCode(this.wire);

  /// The exact uppercase wire string this value corresponds to.
  final String wire;

  static final Map<String, AuthErrorCode> _byWire = <String, AuthErrorCode>{
    for (final code in AuthErrorCode.values) code.wire: code,
  };

  /// Maps a wire `code` string to an [AuthErrorCode].
  ///
  /// Matching is exact and case-sensitive against the documented uppercase
  /// codes. Unrecognised or `null` values map to [AuthErrorCode.unknown].
  static AuthErrorCode fromWire(String? code) {
    if (code == null) return AuthErrorCode.unknown;
    return _byWire[code] ?? AuthErrorCode.unknown;
  }
}
