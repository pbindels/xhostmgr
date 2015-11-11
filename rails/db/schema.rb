# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20140624204554) do

  create_table "host_types", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "hosts", :force => true do |t|
    t.string   "name"
    t.string   "ipaddr"
    t.string   "location"
    t.string   "macaddr"
    t.string   "user_groups"
    t.string   "hostrole"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
    t.string   "product"
    t.string   "environment"
    t.string   "host_groups"
    t.string   "con_macaddr"
    t.string   "os_version"
    t.string   "serial_number"
    t.string   "con_ipaddr"
    t.string   "con_name"
    t.boolean  "is_ipmi"
    t.string   "name_server"
    t.string   "boot_server"
    t.string   "gateway"
    t.string   "netmask"
    t.boolean  "ks_regen"
    t.string   "root_disk"
    t.boolean  "synto"
    t.string   "physical_location"
    t.string   "host_type"
    t.string   "esx_host"
    t.integer  "cage"
    t.integer  "rack"
    t.integer  "start_unit"
    t.integer  "unit_range"
    t.string   "geo_location"
  end

  create_table "products", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "roles", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

end
