class SessionsController < ApplicationController
  
  require 'open-uri'
  
  def new
    session[:referer] = request.env["HTTP_REFERER"]    
  end

  def destroy
    session["user_id"] = nil
    session["username"] = nil
    session["admin"] = nil
    session["image"] = nil
    session["firstname"] = nil
    session["lastname"] = nil
    session["email"] = nil
    session['uid'] = nil
    session['provider'] = nil
    session['access_token'] = nil 
    session["trustee"] = nil
    
    # remove remember me cookie
    cookies.delete(:auth_token)
    
    redirect_to root_url, :notice => "Logged out"
  end
  
  
  def create

    # render :text => omniauth.to_yaml
    # return
    
    # get the service parameter from the Rails router
    params[:service] ? service_route = params[:service] : service_route = 'No service recognized (invalid callback)'

    # get the full hash from omniauth
    omniauth = request.env['omniauth.auth']
        
    # map the returned hashes to our variables first - the hashes differs for every service
    
    # create a new hash
    @authhash = Hash.new
    
    if service_route == 'github'
      
      omniauth['uid'] ? @authhash[:uid] = omniauth['uid'].to_s : @authhash[:uid] = ''
      omniauth['info']['email'] ? @authhash[:email] =  omniauth['info']['email'] : @authhash[:email] = ''
      omniauth['info']['nickname'] ? @authhash[:nickname] =  omniauth['info']['nickname'] : @authhash[:nickname] = ''
      omniauth['info']['name'] ? @authhash[:name] =  omniauth['info']['name'] : @authhash[:name] = ''
      omniauth['provider'] ? @authhash[:provider] = omniauth['provider'] : @authhash[:provider] = ''        

      omniauth['info']['urls']['GitHub'] ? @authhash[:url] = omniauth['info']['urls']['GitHub'] : @authhash[:url] = ''            
      omniauth['extra']['raw_info']['avatar_url'] ? @authhash[:photo] = omniauth['extra']['raw_info']['avatar_url'] : @authhash[:photo] = ''        
      
      omniauth['credentials']['token'] ? @authhash[:token] = omniauth['credentials']['token'] : @authhash[:token] = ''        
                      
    else        
      # debug to output the hash that has been returned when adding new services
      render :text => omniauth.to_yaml
      return
    end 

    if @authhash[:uid] != '' and @authhash[:provider] != ''
      
      @auth = User.find_by_uid(@authhash[:uid])

      if !@auth 
        # register
        @auth = User.new
      end 
      
      # login and update account
      @auth.uid = @authhash[:uid]
      @auth.username = @authhash[:nickname]
      @auth.email = @authhash[:email]

      fullname = @authhash[:name].split(' ')
      @auth.first_name = fullname[0]
      @auth.first_name = fullname[1]
        
      @auth.provider = @authhash[:provider]
      @auth.access_token = @authhash[:token]  

      @auth.photo = @authhash[:photo]
      @auth.website = @authhash[:url]
    
      @auth.save

      session["user_id"] = @auth.id
      session['uid'] = @authhash[:uid]
      session['username'] = @authhash[:nickname]
      session['fullname'] = @authhash[:name]
      session['photo'] = @authhash[:photo]
      session['access_token'] = @authhash[:token]  
        
      redirect_to "/"
        
      
    else
      flash[:notice] =  'Error while authenticating via ' + @authhash[:provider].capitalize + '. The service returned invalid data for the user id.'
      redirect_to root_url
    end
      
  end
  
  # callback: failure
  def failure
    flash[:notice] = 'There was an error at the remote authentication service. You have not been signed in.'
    redirect_to root_url
  end  
  
end