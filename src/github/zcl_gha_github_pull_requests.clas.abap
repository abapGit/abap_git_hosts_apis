CLASS zcl_gha_github_pull_requests DEFINITION
  PUBLIC
  CREATE PROTECTED

  GLOBAL FRIENDS zcl_gha_github_factory .

  PUBLIC SECTION.

    INTERFACES zif_gha_github_pull_requests .
  PROTECTED SECTION.

    DATA mv_owner TYPE string .
    DATA mv_repo TYPE string .

    METHODS parse_create
      IMPORTING
        !iv_json         TYPE string
      RETURNING
        VALUE(rv_number) TYPE i .
    METHODS parse_list
      IMPORTING
        !iv_json       TYPE string
      RETURNING
        VALUE(rt_list) TYPE zif_gha_github_pull_requests=>ty_list_tt .
    METHODS constructor
      IMPORTING
        !iv_owner TYPE string
        !iv_repo  TYPE string .
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_GHA_GITHUB_PULL_REQUESTS IMPLEMENTATION.


  METHOD constructor.

    mv_owner = iv_owner.
    mv_repo = iv_repo.

  ENDMETHOD.


  METHOD parse_create.

    DATA(lo_json) = NEW zcl_gha_json_parser( iv_json ).

    rv_number = lo_json->value_integer( '/id' ).

  ENDMETHOD.


  METHOD parse_list.

    DATA(lo_json) = NEW zcl_gha_json_parser( iv_json ).

    LOOP AT lo_json->members( '' ) INTO DATA(lv_member) WHERE NOT table_line IS INITIAL.
      APPEND VALUE #(
        number   = lo_json->value_integer( |/{ lv_member }/number| )
        title    = lo_json->value( |/{ lv_member }/title| )
        state    = lo_json->value( |/{ lv_member }/state| )
        html_url = lo_json->value( |/{ lv_member }/html_url| )
        body     = lo_json->value( |/{ lv_member }/body| )
        base_ref = lo_json->value( |/{ lv_member }/base/ref| )
        base_sha = lo_json->value( |/{ lv_member }/base/sha| )
        head_ref = lo_json->value( |/{ lv_member }/head/ref| )
        head_sha = lo_json->value( |/{ lv_member }/head/sha| )
        ) TO rt_list.
    ENDLOOP.

  ENDMETHOD.


  METHOD zif_gha_github_pull_requests~create.

    DATA(lo_client) = zcl_gha_http_client=>create_by_url(
      |https://api.github.com/repos/{ mv_owner }/{ mv_repo }/pulls| ).

    lo_client->set_method( 'POST' ).

    DATA(lv_json) = |\{"title": "{ iv_title }",\n| &&
      |"head": "{ iv_head }",\n| &&
      |"body": "{ iv_body }",\n| &&
      |"base": "{ iv_base }"\}\n|.
    lo_client->set_cdata( lv_json ).

    DATA(li_response) = lo_client->send_receive( ).

    DATA(lv_cdata) = li_response->get_cdata( ).

    li_response->get_status( IMPORTING code = DATA(lv_code) reason = DATA(lv_reason) ).
    IF lv_code <> 201.
      BREAK-POINT.
    ENDIF.

    rv_number = parse_create( lv_cdata ).

  ENDMETHOD.


  METHOD zif_gha_github_pull_requests~get.

    ASSERT 0 = 1. " todo

  ENDMETHOD.


  METHOD zif_gha_github_pull_requests~list.

* todo, add parameters: state + head + base + sort + direction

    DATA(lo_client) = zcl_gha_http_client=>create_by_url(
      |https://api.github.com/repos/{ mv_owner }/{ mv_repo }/pulls| ).

    DATA(li_response) = lo_client->send_receive( ).

    DATA(lv_data) = li_response->get_cdata( ).

*    DATA: lt_fields TYPE tihttpnvp.
*    li_response->get_header_fields( CHANGING fields = lt_fields ).

    li_response->get_status( IMPORTING code = DATA(lv_code) reason = DATA(lv_reason) ).
    IF lv_code <> 200.
      BREAK-POINT.
    ENDIF.

* todo, handle rate limit error
* todo, pagination?

    rt_list = parse_list( lv_data ).

  ENDMETHOD.
ENDCLASS.
