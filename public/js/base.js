/* 控制导航按钮动作 */
function nav_click(is_show) {
  if (is_show) {
    /* 显示左侧aside */
    $('.aside')
      .addClass('visible-md visible-lg')
      .removeClass('hidden-md hidden-lg')
    /* 调整右侧内容 */
    $('.aside3')
      .removeClass('col-md-13 col-lg-13')
      .addClass('col-md-13 col-lg-13');
    /* 调整文字内容格式 */
    $('.aside3-content')
      .removeClass('col-md-10 col-lg-8 col-md-offset-1 col-lg-offset-2')
      .addClass('col-md-13');
  } else {
    /* 隐藏左侧aside */
    $('.aside')
      .removeClass('visible-md visible-lg')
      .addClass('hidden-md hidden-lg');
    /* 右侧内容最大化 */
    $('.aside3')
      .removeClass('col-md-13 col-lg-13')
      .addClass('col-md-13 col-lg-13');
    /* 修改文字排版 */
    $('.aside3-content')
      .removeClass('col-md-13')
      .addClass('col-md-10 col-lg-8 col-md-offset-1 col-lg-offset-2'); 
  }  /*col-md-offset-1 col-lg-offset-2*/
}
/* 控制文章章节列表按钮 */
function content_click(is_show){
  if (is_show) {
    $('#content_table').show();
    $('#content_btn i').removeClass('fa-plus').addClass('fa-minus');
  } else {
    $('#content_table').hide();
    $('#content_btn i').removeClass('fa-minus').addClass('fa-plus');
  }
}

/* 修复 `归档`、`关于`点击后不能显示为激活状态 */
function aside_click_patch(){
  $('.nav-stacked li > a.pjaxlink').bind('click', function() {
    $('.nav-stacked > li.active').removeClass('active');
    $(this).parent('li').first().addClass('active');
  });
}

/* 文章列表点击后，对应文章显示激活状态 */
function aside2_link_patch() {
  $('.aside2 a.pjaxlink').bind('click', function() {
    $('.aside2 a.pjaxlink.active').removeClass('active');
    $(this).addClass('active');
  });

  $('.nav-stacked li > a').bind('click', function() {
    $('.list-group a.active').removeClass('active');
  });
}

function nav_link_patch() {
  // Smooth scrolling
  $('#content_table a').on('click', function() {
    var target = $(this.hash);
    target.addClass('flash').delay(700).queue(function() {
      $(this).removeClass('flash').dequeue();
    });
  });
}

/* 文章导航列表 */
function contentEffects(){
  //remove the asidebar
  $('.row-offcanvas').removeClass('active');
  if($("#nav").length > 0){
    $("#content > h2,#content > h3,#content > h4,#content > h5,#content > h6").each(function() {
        var current = $(this);
        // current.attr("id", "title" + i);
        current.attr('id', function() {
          var ID = "",
              alphabet = "abcdefghijklmnopqrstuvwxyz";

          for(var i=0; i < 5; i++) {
            ID += alphabet.charAt(Math.floor(Math.random() * alphabet.length));
          }
          return ID;
        }); 

        tag = current.prop('tagName').substr(-1);
        $("#nav").append("<li><a class='level" + tag + "' href='#" + $(this).attr('id') + "'>" + current.text() + "</a></li>");
    }); 
    $("pre").addClass("prettyprint");
    prettyPrint(); 
    $('#content img').addClass('img-thumbnail').parent('p').addClass('center');
    $('#content_btn').show();
    // $('#content_btn .fa-minus').size() > 0 && $('#content_btn').trigger('click') //保证关闭状态
    $('#content_btn .fa-minus').size() > 0 && $('#content_table').show(); //保证内容可见
  }else{
    $('#content_btn').hide();
  }
  nav_link_patch();
}

$(document).ready(function() {
  /* 控制左侧 aside 的动作 */
  $("#nav_btn").on('click', function() {
    isClicked = $(this).data('clicked');

    nav_click(isClicked);

    $(this).data('clicked', !isClicked);
  });

  $("#content_btn").on('click', function(){
    isClicked = $(this).data('clicked');

    content_click(!isClicked);

    $(this).data('clicked',!isClicked);

  });

  $(document).pjax('.pjaxlink', '#pjax', { fragment: "#pjax", timeout: 10000 });
  $(document).on({
    'pjax:click': function() {
      $('#pjax').removeClass('fadeIn').addClass('fadeOut');
      NProgress.start();
    },
    'pjax:start': function() {
      $('#pjax').css({'opacity':0});
    },
    'pjax:end': function() {
      NProgress.done();
      $('container').scrollTop(0);
      $('#pjax').css({'opacity':1}).removeClass('fadeOut').addClass('fadeIn');

      if ($("body").find('.container').width() < 992)
      $('#nav_btn').click();
      $('.aside3').scrollTop(0);
      contentEffects();
    }
  });
  $('body').on('click', '.show-commend', function(){
    var ds_loaded = false;
    window.disqus_shortname = $('.show-commend').attr('name');
    $.ajax({
      type: "GET",
      url: "http://" + disqus_shortname + ".disqus.com/embed.js",
      dataType: "script",
      cache: true,
      success: function() {
        $('.show-commend').hide();
      }
    });
  });
  contentEffects();
  aside_click_patch();
  aside2_link_patch();
});
