class UserMailer < ApplicationMailer
  def achievement_earned(user, achievement)
    @user = user
    @achievement = achievement

    mail(
      to: @user.email,
      subject: "You've earned a new achievement: #{@achievement.name}!"
    )
  end
end
