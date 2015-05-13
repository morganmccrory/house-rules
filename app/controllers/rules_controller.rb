class RulesController < ApplicationController
skip_before_action :authenticate_user_from_token!

  def index
    @house = House.find_by(id: params[:house_id])
    if @user = current_user
      @user_house = @user.houses.first
      if @user_house == @house
        @rules = @house.rules
      else
        redirect_to "/houses/#{@user_house.id}/rules"
      end
    else
      redirect_to "/login"
    end
  end

  def create
    @user = current_user
    @house = House.find(params[:house_id])
    @rule = @house.rules.new(rule_params)
    @rule.save
    @notification = Notification.create(alert: "#{current_user.first_name} has added #{@rule.content} to the house rules.", category: "rules", house_id: @house.id)
    HousingAssignment.where(house_id: @house.id).select do |assignment|
      assignment.user.user_notifications.create(notification: @notification)
    end
    if request.xhr?
      render @rule, layout: false
    else
      if request.xhr?
        render '/rules/rule_must_be_length_6.html.erb', layout: false
      end
    end
  end

  def update
    @user = current_user
    @house = House.find(params[:house_id])
    @rule = Rule.find(params[:id])
    if @rule.update_attributes(rule_params)
      @notification = Notification.create(alert: "#{current_user.first_name} has updated #{@rule.content}.", category: "rules", house_id: @house.id)
      HousingAssignment.where(house_id: @house.id).select do |assignment|
        assignment.user.user_notifications.create(notification: @notification)
      end
      if request.xhr?
        render :json => {
              :rule => @rule
          }
      else
        redirect_to house_rules_path(@house)
      end
    end
  end

  def destroy
    if @user = current_user
      @house = House.find(params[:house_id])
      @rule = Rule.find_by(id: params[:id])
      if request.xhr?
        @rule.destroy
        @notification = Notification.create(alert: "#{current_user.first_name} has deleted #{@rule.content}.", category: "rules", house_id: @house.id)
        HousingAssignment.where(house_id: @house.id).select do |assignment|
          assignment.user.user_notifications.create(notification: @notification)
        render :nothing => true, :status => 200
        end
      else
        redirect_to house_messages_path(@house)
      end
    else
      redirect_to '/login'
    end
  end

  private

  def rule_params
    params.require(:rule).permit(:content)
  end
end
