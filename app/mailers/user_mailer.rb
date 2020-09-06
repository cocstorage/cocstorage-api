class UserMailer < ApplicationMailer
  def authentication_email(user)
    @uuid = user.user_email_access_log.access_uuid
    @email = user.email
    mail(from: '개념글 저장소 <cocstoragehelps@gmail.com>', to: @email, subject: '이메일 인증을 완료해주세요.')
  end
end
