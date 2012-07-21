
class RemoteSmsController < ApplicationController
  include RemoteSmsHelper #USES HELPER FUNCTION TO CONTROL WHETHER SMS IS SENT TO PHONE OR JUST LOGGED
  
  # GET /remote_sms
  # GET /remote_sms.json
  def index
    @remote_sms = RemoteSm.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @remote_sms }
    end
  end

  # GET /remote_sms/1
  # GET /remote_sms/1.json
  def show
    @remote_sm = RemoteSm.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @remote_sm }
    end
  end

  # GET /remote_sms/new
  # GET /remote_sms/new.json
  def new
    @remote_sm = RemoteSm.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @remote_sm }
    end
  end

  # GET /remote_sms/1/edit
  def edit
    @remote_sm = RemoteSm.find(params[:id])
  end

  # POST /remote_sms
  # POST /remote_sms.json
  def create
    @remote_sm = nil
    
    logger.info("received an SMS: #{params}") #LOG EACH MESSAGE
    
    if params[:remote_sm] #!!!NEED TO UNDERSTAND WHEN THIS IS TRUE AND WHEN FALSE....!!!
      @remote_sm = RemoteSm.new(params[:remote_sm])
      
      respond_to do |format| #STUFF THAT WAS THERE BEFORE (SAVING A NEW REMOTE SMS)
        if @remote_sm.save
          format.html { redirect_to @remote_sm, notice: 'Remote sm was successfully created.' }
          format.json { render json: @remote_sm, status: :created, location: @remote_sm }
        else
          format.html { render action: "new" }
          format.json { render json: @remote_sm.errors, status: :unprocessable_entity }
        end
      end
    else
      subset = {}
      subset[:from] = params[:from]
      subset[:message] = params[:message]
      subset[:secret] = params[:secret]
      #CREATED 'SUBSET' BECAUSE OUR INPUT HAS MORE PARAMETERS THAN WE NEED TO SAVE
      @remote_sm = RemoteSm.new(subset)
      success = @remote_sm.save
      if success
        sendSMS(@remote_sm.from,'Kikko!') #USES sendSMS FUNCTION FROM REMOTE SMS HELPER TO MOCK THE SENDING OF A MESSAGE
      end

      respond_to do |format|
        if success
          format.html { render :nothing => true, :status => 201 }
          format.json { render :json => '{"payload" : {"success" : true}}', :status => 201 } #PAYLOAD IS WHAT SMSSYNC EXPECTS TO SEE
        else
          format.html { render :nothing => true, :status => 500 }
          format.json { render :json => '{"payload" : {"success" : false}}', :status => 500 }
        end
      end
    end
    logger.info("received an SMS: #{@remote_sm}") #LOG EACH MESSAGE

  end

  # PUT /remote_sms/1
  # PUT /remote_sms/1.json
  def update
    @remote_sm = RemoteSm.find(params[:id])

    respond_to do |format|
      if @remote_sm.update_attributes(params[:remote_sm])
        format.html { redirect_to @remote_sm, notice: 'Remote sm was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @remote_sm.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /remote_sms/1
  # DELETE /remote_sms/1.json
  def destroy
    @remote_sm = RemoteSm.find(params[:id])
    @remote_sm.destroy

    respond_to do |format|
      format.html { redirect_to remote_sms_url }
      format.json { head :no_content }
    end
  end
end
