using Toybox.WatchUi as Ui;
using Toybox.Communications as Comm;
using Hass;

using Utils;

(:glance)
class GlanceController {
  hidden var _mTypes = [
    Hass.TYPE_LIGHT,
    Hass.TYPE_SWITCH,
    Hass.TYPE_AUTOMATION,
    Hass.TYPE_SCRIPT,
    Hass.TYPE_LOCK,
    Hass.TYPE_COVER,
    Hass.TYPE_BINARY_SENSOR,
    Hass.TYPE_INPUT_BOOLEAN
  ];
  hidden var _mSummaries = {};

  function initialize() {
    refreshSummaries();
  }

  function _onReceiveSummary(err, data) {
    if (err != null) {
      // TODO
      return;
    }
    _mSummaries = data[:body];
    Ui.requestUpdate();
  }

  function refreshSummaries() {
    // get rekt
    var group = Hass.getGroup();
    if (group == null || group.find("group.") == null) {
      System.println(group + "\nis not a valid\ngroup");
      return;
    }

    var templateString = "{% set group = '" + group + "' %}" +
      "{% set comma = joiner(',') %}" +
      "{ {% for domain, entities in expand(group)|groupby('domain')%}" +
      "{{comma()}} {{domain|tojson}}: \\\"{{entities|selectattr('state', 'in', ['on','unlocked','open'])|list|length}}/{{entities|length}}\\\"" +
      "{% endfor %} }";
    if (Hass.client != null) {
      Hass.client.getTemplate(
        templateString,
        { :types => _mTypes },
        { :responseType => Comm.HTTP_RESPONSE_CONTENT_TYPE_JSON },
        method(:_onReceiveSummary)
      );
    }
  }

  function getSummaries() {
    return _mSummaries;
  }
}

(:glance)
class AppGlance extends Ui.GlanceView {
  hidden var _mController;
  hidden const _mHeaderText = Ui.loadResource(Rez.Strings.AppName).toUpper();

  function initialize(controller) {
    GlanceView.initialize();
    _mController = controller;
  }

  function getLayout() {
    setLayout([]);
  }

  function onUpdate(dc) {
    View.onUpdate(dc);

    var summaries = _mController.getSummaries();

    GlanceView.onUpdate(dc);

    var canvasHeight = dc.getHeight();
    var canvasCenterY = canvasHeight / 2;

    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);

    var headerFont = Graphics.FONT_GLANCE;
    var headerHeight = dc.getTextDimensions(_mHeaderText, headerFont)[1];

    var mainFont = Graphics.FONT_GLANCE_NUMBER;
    var mainHeight = dc.getTextDimensions("foo", mainFont)[1];

    var bodyHeight = headerHeight + mainHeight;
    var bodyCenterY = bodyHeight / 2;
    var bodyY = canvasCenterY - bodyCenterY;

    var headerY = bodyY;
    var mainTextY = bodyY + headerHeight;
    var mainBitmapY = mainTextY + (mainHeight - 24) / 2;

    dc.drawText(0, headerY, headerFont, _mHeaderText, Graphics.TEXT_JUSTIFY_LEFT);

    var mainX = 0;
    var domains = summaries.keys();
    for (var i = 0; i < domains.size(); i++) {
      var domain = domains[i];
      var bitmap = WatchUi.loadResource(Rez.Drawables.DomainLight);
      var summary = summaries[domain];
      var xOffset = mainX + dc.getTextDimensions(summary, mainFont)[0] + 2;
      dc.drawText(mainX, mainTextY, mainFont, summary, Graphics.TEXT_JUSTIFY_LEFT);
      dc.drawBitmap(xOffset, mainBitmapY, bitmap);
      mainX = xOffset + 8;
    }

  }
}
