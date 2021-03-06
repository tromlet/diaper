class BarcodeItemsController < ApplicationController
  def index
    @items = Item.gather_items(current_organization, @global)
    @canonical_items = CanonicalItem.all
    @barcode_items = current_organization.barcode_items.include_global(false).filter(filter_params)
  end

  def create
    @barcode_item = current_organization.barcode_items.new(barcode_item_params)
    if @barcode_item.save
      msg = "New barcode added to your private set!"
      respond_to do |format|
        format.json { render json: @barcode_item.to_json }
        format.js
        format.html { redirect_to barcode_items_path, notice: msg }
      end
    else
      flash[:error] = "Something didn't work quite right -- try again?"
      render action: :new
    end
  end

  def new
    @barcode_item = current_organization.barcode_items.new
    @items = current_organization.items
  end

  def edit
    @barcode_item = current_organization.barcode_items.includes(:barcodeable).find(params[:id])
    @items = current_organization.items
  end

  def show
    @barcode_item = current_organization.barcode_items.includes(:barcodeable).find(params[:id])
  end

  def find
    @barcode_item = current_organization.barcode_items.includes(:barcodeable).include_global(true).find_by!(value: barcode_item_params[:value])
    respond_to do |format|
      format.json { render json: @barcode_item.to_json }
    end
  end

  def update
    @barcode_item = current_organization.barcode_items.find(params[:id])
    if @barcode_item.update(barcode_item_params)
      redirect_to barcode_items_path, notice: "Barcode updated!"
    else
      flash[:error] = "Something didn't work quite right -- try again?"
      render action: :edit
    end
  end

  def destroy
    begin
      barcode = current_organization.barcode_items.find(params[:id])
      raise if barcode.nil? || barcode.global?

      barcode.destroy
    rescue Exception => e
      flash[:error] = "Sorry, you don't have permission to delete this barcode."
    end
    redirect_to barcode_items_path
  end

  private

  def barcode_item_params
    params.require(:barcode_item).permit(:value, :barcodeable_id, :quantity).merge(organization_id: current_organization.id)
  end

  def filter_params
    return {} unless params.key?(:filters)

    params.require(:filters).slice(:barcodeable_id, :by_item_partner_key, :by_value)
  end
end
