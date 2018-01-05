function setColorById(id,sColor) {
  var elem;
  if (document.getElementById) {
    if (elem=document.getElementById(id)) {
      if (elem.style) {
        if(sColor == "green") {
          elem.style.color=sColor;
          elem.textContent=" SHAInet Running";
        }
        else {
          elem.style.color=sColor;
          elem.textContent=" SHAInet Not Running!";
        }
      }
    }
  }
}
function update(retries) {
  $.ajax({
    type: "GET",
    url: "/isready",
    success: function (data, status, jqXHR) {
      console.log("success: " + data);
      if(data == "ready") {
        console.log("ready");
        setColorById("status", "green")
        var myImageElement = document.getElementById('svg');
        myImageElement.src = 'svg/nodes.svg?rand=' + Math.random();
      }
      else if(data == "busy") {
        console.log("busy");
        retries += 1;
        if(retries < 3) {
          setTimeout(function() {
            console.log("retrying");
            update(retries);
          }, 100);
        };
      };
    },
    error: function (jqXHR, status) {
      setColorById("status", "red");
      console.log("aborted");
    }
  });
}
setInterval(function() {
  update(0);
}, 1000);
