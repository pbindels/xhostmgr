class HostTypesController < ApplicationController
  # GET /host_types
  # GET /host_types.json
  def index
    @host_types = HostType.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @host_types }
    end
  end

  # GET /host_types/1
  # GET /host_types/1.json
  def show
    @host_type = HostType.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @host_type }
    end
  end

  # GET /host_types/new
  # GET /host_types/new.json
  def new
    @host_type = HostType.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @host_type }
    end
  end

  # GET /host_types/1/edit
  def edit
    @host_type = HostType.find(params[:id])
  end

  # POST /host_types
  # POST /host_types.json
  def create
    @host_type = HostType.new(params[:host_type])

    respond_to do |format|
      if @host_type.save
        format.html { redirect_to @host_type, notice: 'Host type was successfully created.' }
        format.json { render json: @host_type, status: :created, location: @host_type }
      else
        format.html { render action: "new" }
        format.json { render json: @host_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /host_types/1
  # PUT /host_types/1.json
  def update
    @host_type = HostType.find(params[:id])

    respond_to do |format|
      if @host_type.update_attributes(params[:host_type])
        format.html { redirect_to @host_type, notice: 'Host type was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @host_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /host_types/1
  # DELETE /host_types/1.json
  def destroy
    @host_type = HostType.find(params[:id])
    @host_type.destroy

    respond_to do |format|
      format.html { redirect_to host_types_url }
      format.json { head :no_content }
    end
  end
end
