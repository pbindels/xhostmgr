$(document).ready(function() {

    $('#text_box_label').focus();
    $('#text_box_label').on('change', function() {
        console.log("here88")
        $("#actions").focus;
    });

    // Check for Redhat OS and get license
    $('.redhat').hide();
    var pattern = /RHEL/;
    var os = $('.os_version :selected').text();
    if (pattern.test(os)) {
        $('.redhat').show();
    };
    $('.os_version').on('change', function() {
        var os = $('.os_version :selected').text();
        if (pattern.test(os)) {
            $('.redhat').show();
        }
        else {
            $('.redhat').hide();
        }
    });

    // Host type, Physical location or ESX host
    $('.select_device').show();
    $('.enter_physical_location').hide();
    $('.show_esx_host').hide();

    var device = $('.select_device :selected').text();
    if ( device === "Select Host Type")  {
        $('.enter_physical_location').hide();
        $('.show_esx_host').hide();
    }
    else {
        if (device === "VMware") {
            $('.show_esx_host').show();
        } else {
            $('.enter_physical_location').show();
        }
    }

    $('.select_device').on('change', function() {
        var device = $('.select_device :selected').text();
        if (device === "VMware") {
           $('.enter_physical_location').hide();
           $('.show_esx_host').show();
        }
        else {
           $('.enter_physical_location').show();
           $('.show_esx_host').hide();
        }
    });
    // End Host Type Section


    $("#task_name").bind("change", function() {
        // $("form").trigger("submit");
        $('#task_spinner').show();
        $("form:first").trigger("submit");
    });


    if ((document.getElementById('host_manual_host')) && (document.getElementById('host_manual_host').checked)){
        console.log("it's checked");
    }
    else{
        console.log("it's not checked") ;
    }

    console.log("here");
    if ((document.getElementById('host_manual_host')) && (document.getElementById('host_manual_host').checked)){
        console.log("is true")  ;
        $('.focus_row_host').show();
        $('.field9999').hide();
    }
    else
    {
        console.log("is false") ;

        $('.focus_row_host').hide() ;
        $('.field9999').show();
    }
        $('.checkbox_manual').on('change', function() {
        $('.focus_row_host').toggle();
        $('.field9999').toggle();
    });


    console.log("herephysical");
    if ((document.getElementById('host_physical_host')) && (document.getElementById('host_physical_host').checked)){
        console.log("is true physical")  ;
        //$('.focus_row_host').show();
        $('.field7777').hide();
    }
    else
    {
        console.log("is false physical") ;

        //$('.focus_row_host').hide() ;
        $('.field7777').hide();
    }
    $('.checkbox_physical').on('change', function() {
        //$('.focus_row_host').toggle();
        $('.field7777').toggle();
    });


    //var str = $('.radio1 :selected').value();
//    var str = $("input[type='radio'].radioBtnClass").is(':checked');
    var str = $("input[type='radio'].radioBtnClass").is(':checked');
    if (document.getElementById('host_is_ipmi') ){
    var ipmi = (document.getElementById('host_is_ipmi').checked);
    console.log(ipmi);
    console.log("here2")
    console.log(str)
   // if (str == "true" || ipmi == "true" ) {
    if ( ipmi )  {
        console.log("yes ipmi")
        $('.focus_row1').show();
        $('.focus_row2').show();
        $('.focus_row3').hide();
        $('.focus_row4').show();
        $('#newuser').show();
    }
    else {
        console.log("here")
        $('.focus_row1').hide();
        $('.focus_row2').hide();
        $('.focus_row3').show();
        $('.focus_row4').hide();
        $('#newuser').hide();
    }
    }

    $('.radio1').on('change', function() {
        $('.focus_row1').toggle();
        $('.focus_row2').toggle();
        $('.focus_row3').toggle();
        $('.focus_row4').toggle();
        $('#newuser').toggle();
    })

    $('.radio2').on('change', function() {
        $('.focus_row1').toggle();
        $('.focus_row2').toggle();
        $('.focus_row3').toggle();
        $('.focus_row4').toggle();
        $('#newuser').toggle();
    })

    $(document).ready(function() {
        $('#user').hover(function() {
            $('#popup').show();
        }, function() {
            $('#popup').hide();
        });
    });

    $(document).ready(function() {
        $('#newuser').hover(function() {
            $('#new').show();
        }, function() {
            $('#new').hide();
        });
    });

    $(document).ready(function() {
        $('#loc').hover(function() {
            $('#loc-popup').show();
        }, function() {
            $('#loc-popup').hide();
        });
    });

    $(document).ready(function() {
        $('#disable').hover(function() {
            $('#disable-popup').show();
        }, function() {
            $('#disable-popup').hide();
        });
    });
/*
    $('table.imagetable .node').click(function() {
        $(this).toggleClass("clicked");
        console.log("node")
    });

    $('tr').click(function() {
        $(this).toggleClass("clicked");
        console.log("tr")
    });
  */
  $('table.imagetable tr').click(function() {
        $(this).toggleClass("clicked");
        console.log("here22")
    });
/*
    $('table.imagetable .even td').click(function() {
        $(this).toggleClass("clicked");
        console.log("here44")
    });
    */
/*

    $('table.imagetable .odd td').click(function() {
        $(this).toggleClass("clicked");
        console.log("here2")
    });

    $('table.imagetable .even td').click(function() {
        $(this).toggleClass("clicked");
        console.log("here4")
    });
 */

});
