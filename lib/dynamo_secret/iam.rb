require 'aws-sdk-iam'

module DynamoSecret
  class IAM
    def user_id
      @user ||= Aws::IAM::CurrentUser.new(region: 'us-west-2')
      @user.user_name || @user.user_id
    end
  end
end
