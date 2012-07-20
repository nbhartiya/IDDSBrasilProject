require 'test_helper'

class RemoteSmsControllerTest < ActionController::TestCase
  setup do
    @remote_sm = remote_sms(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:remote_sms)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create remote_sm" do
    assert_difference('RemoteSm.count') do
      post :create, remote_sm: { from: @remote_sm.from, message: @remote_sm.message, secret: @remote_sm.secret }
    end

    assert_redirected_to remote_sm_path(assigns(:remote_sm))
  end

  test "should show remote_sm" do
    get :show, id: @remote_sm
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @remote_sm
    assert_response :success
  end

  test "should update remote_sm" do
    put :update, id: @remote_sm, remote_sm: { from: @remote_sm.from, message: @remote_sm.message, secret: @remote_sm.secret }
    assert_redirected_to remote_sm_path(assigns(:remote_sm))
  end

  test "should destroy remote_sm" do
    assert_difference('RemoteSm.count', -1) do
      delete :destroy, id: @remote_sm
    end

    assert_redirected_to remote_sms_path
  end
end
