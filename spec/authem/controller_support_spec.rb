require 'spec_helper'

describe Authem::ControllerSupport do
  subject { controller }

  let!(:user) { PrimaryStrategyUser.create(:email => 'some@guy.com', :password => 'password') }
  let(:controller) { AuthenticatedController.new }
  let(:cookies) { MockCookies.new }
  let(:session) { {}.with_indifferent_access }
  let(:request) { mock(:request) }

  before do
    controller.stub(:cookies).and_return(cookies)
    controller.stub(:session).and_return(session)
    controller.stub(:request).and_return(request)
  end

  describe '#sign_in' do
    context 'with remember me on' do
      before { controller.send(:sign_in, user) }
      its(:current_user) { should == user }
      it { session[:session_token].should == user.session_token }
      it { cookies[:remember_token].should == user.remember_token }
    end

    context 'with remember me off' do
      before { controller.send(:sign_in, user, false) }
      its(:current_user) { should == user }
      it { session[:session_token].should == user.session_token }
      it { cookies[:remember_token].should be_nil }
    end
  end

  describe '#sign_out' do
    it 'resets the session' do
      cookies.should_receive(:[]=).with(:remember_token, nil)
      controller.should_receive(:reset_session)
      controller.send(:sign_out)
      controller.send(:current_user).should be_nil
    end
  end

  describe '#current_user' do
    subject { controller.send(:current_user) }

    context 'without an established presence' do
      it { should be_nil }
    end

    context 'with a token in the session' do
      before { session[:session_token] = user.session_token }
      it { should == user }
    end

    context 'without a remember me token' do
      before { cookies[:remember_token] = "" }
      it { should be_nil }
    end

    context 'with a remember me token' do
      before { cookies[:remember_token] = user.remember_token }
      it { should == user }
      it 'sets the session token' do
        subject
        session[:session_token].should == user.reload.session_token
      end
    end

    context 'with an invalid remember me token' do
      before { cookies[:remember_token] = 945 }
      it { should be_nil }
    end
  end

  describe '#require_user' do
    context 'with an established user' do
      before { controller.send(:sign_in, user) }
      it 'does not issue a redirect' do
        controller.should_not_receive(:redirect_to)
        controller.send(:require_user)
      end
    end

    context 'without an established user' do
      it 'issues a redirect' do
        request.should_receive(:url)
        controller.should_receive(:redirect_to).with(:sign_in)
        controller.send(:require_user)
      end
    end
  end

  describe '#redirect_back_or_to' do
    context 'with a return_to_url' do
      before { session[:return_to_url] = :dashboard }

      it 'clears and redirects to the return to url' do
        controller.should_receive(:redirect_to).with(:dashboard, :flash => {})
        controller.send :redirect_back_or_to, :somewhere
        session[:return_to_url].should be_nil
      end
    end
  end
end
