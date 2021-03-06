require 'spec_helper'

describe Archive do

	describe '::get_dates' do
		before :each do
			@param_possibilities = YAML.load_file(Rails.root.join("spec/fixtures/fake_params_hash.yml"))
		end

		context 'no date info filled in:' do
			it 'selects Jan 1, 2011 through Dec 31 of the current year' do
				Archive.get_dates(@param_possibilities['one']).should == 
								[Date.new(2011, 1, 1), Date.new(Time.now.year, 12, 31)]
			end
		end

		context 'only years filled in:' do
			it 'selects Jan 1 of the start year through Dec 31 of the end year' do
				Archive.get_dates(@param_possibilities['two']).should == 
								[Date.new(2011, 1, 1), Date.new(2011, 12, 31)]
			end
		end

		context 'start date complete, end date blank:' do
			it 'selects the start date through Dec 31 of the current year' do
				Archive.get_dates(@param_possibilities['three']).should == 
								[Date.new(2011, 9, 3), Date.new(Time.now.year, 12, 31)]
			end
		end

		context 'everything filled in:' do
			it 'selects the start date through the end date' do
				Archive.get_dates(@param_possibilities['four']).should == 
								[Date.new(2011, 11, 10), Date.new(2012, 3, 9)]
			end
		end

		context 'random fields filled in:' do
			it 'substitutes the values supplied into the range Jan 1, 2011 - Dec 31 current year' do
				Archive.get_dates(@param_possibilities['five']).should == 
								[Date.new(2011, 4, 1), Date.new(Time.now.year, 12, 9)]
			end
		end
	end

	describe '#create_statuses!' do
		before :each do
			@archive = FactoryGirl.create(:archive)
			test_users = Koala::Facebook::TestUsers.new(:app_id => Facebook::APP_ID, :secret => Facebook::SECRET)
			user = test_users.create(true, "read_stream")
			@user = FactoryGirl.build(:user, oauth_token: user['access_token'])
			@user.save
		end

		it 'uses Koala to call the Facebook API to get a list of the statuses for the specified time period' do
			Koala::Facebook::API.any_instance.should_receive(:get_connections).with('me', 'statuses')
				.and_return(SAMPLE_API_RESPONSE)
			@archive.create_statuses!
		end
	
		it 'makes sure it has gotten all statuses since the user\'s last login' do
			Koala::Facebook::API.any_instance.stub(:get_connections).and_return(SAMPLE_API_RESPONSE)
			Array.any_instance.stub(:next_page).and_return([SAMPLE_API_RESPONSE, nil].sample)
			DateTime.any_instance.should_receive(:>).with(@user.last_login_at).at_least(:once)
			@archive.create_statuses!
		end

		context 'for each status,' do
			before :each do
				Koala::Facebook::API.any_instance.stub(:get_connections).and_return(SAMPLE_API_RESPONSE)
				Array.any_instance.stub(:next_page).and_return([SAMPLE_API_RESPONSE, nil].sample)
			end

			it 'makes sure the status is not blank' do
				Hash.any_instance.should_receive(:[]).at_least(:once).with('message').and_return('messageee')
		#		String.any_instance.should_receive(:nil?).at_least(:once).and_return(false)
				@archive.create_statuses!
			end

			it 'checks whether the status is already in the database' do
		#		Hash.any_instance.stub(:[]).and_return('messageee')
		#		@user.statuses.should_receive(:method_missing).with(:find_by_message, 'messageee')
				@archive.create_statuses!
			end

			it 'creates an instance of Status for each new status'
		end

		it 'updates last_login_at to the current time' do
			Koala::Facebook::API.any_instance.stub(:get_connections).and_return(SAMPLE_API_RESPONSE)
			Array.any_instance.stub(:next_page).and_return([SAMPLE_API_RESPONSE, nil].sample)
			time = Time.now
			Timecop.freeze(time)
			User.any_instance.should_receive(:update_attributes!).with(last_login_at: Time.now)
			@archive.create_statuses!
			Timecop.return
		end

	end

end
