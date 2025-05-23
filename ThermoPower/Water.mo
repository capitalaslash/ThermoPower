within ThermoPower;
package Water "Models of components with water/steam as working fluid"
  connector Flange "Flange connector for water/steam flows"
    replaceable package Medium = StandardWater constrainedby
      Modelica.Media.Interfaces.PartialMedium "Medium model";
    flow Medium.MassFlowRate m_flow
      "Mass flow rate from the connection point into the component";
    Medium.AbsolutePressure p "Thermodynamic pressure in the connection point";
    stream Medium.SpecificEnthalpy h_outflow
      "Specific thermodynamic enthalpy close to the connection point if m_flow < 0";
    stream Medium.MassFraction Xi_outflow[Medium.nXi]
      "Independent mixture mass fractions m_i/m close to the connection point if m_flow < 0";
    stream Medium.ExtraProperty C_outflow[Medium.nC]
      "Properties c_i/m close to the connection point if m_flow < 0";
    annotation (
      Documentation(info="<HTML>.
</HTML>", revisions="<html>
<ul>
<li><i>16 Dec 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Medium model added.</li>
<li><i>1 Oct 2003</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       First release.</li>
</ul>
</html>"),
      Diagram(graphics),
      Icon(graphics));
  end Flange;

  connector FlangeA "A-type flange connector for water/steam flows"
    extends ThermoPower.Water.Flange;
    annotation (Icon(graphics={Ellipse(
            extent={{-100,100},{100,-100}},
            lineColor={0,0,255},
            fillColor={0,0,255},
            fillPattern=FillPattern.Solid)}));
  end FlangeA;

  connector FlangeB "B-type flange connector for water/steam flows"
    extends ThermoPower.Water.Flange;
    annotation (Icon(graphics={Ellipse(
            extent={{-100,100},{100,-100}},
            lineColor={0,0,255},
            fillColor={0,0,255},
            fillPattern=FillPattern.Solid), Ellipse(
            extent={{-40,40},{40,-40}},
            lineColor={0,0,255},
            fillColor={255,255,255},
            fillPattern=FillPattern.Solid)}));
  end FlangeB;
  extends Modelica.Icons.Package;

  package StandardWater = Modelica.Media.Water.StandardWater;
  model SourcePressure "Pressure source for water/steam flows"
    extends Icons.Water.SourceP;
    replaceable package Medium = StandardWater constrainedby
      Modelica.Media.Interfaces.PartialMedium "Medium model"
      annotation(choicesAllMatching = true);
    type HydraulicResistance = Real (
       final quantity="HydraulicResistance", final unit="Pa/(kg/s)");
    parameter Medium.AbsolutePressure p0=1.01325e5 "Nominal pressure";
    parameter Units.HydraulicResistance R=0 "Hydraulic resistance";
    parameter Boolean use_T = false "Use the temperature if true, otherwise use specific enthalpy";
    parameter Medium.Temperature T = 298.15 "Nominal temperature"
      annotation(Dialog(enable = use_T and not use_in_T));
    parameter Medium.SpecificEnthalpy h=1e5 "Nominal specific enthalpy"
      annotation(Dialog(enable = not use_T and not use_in_h));
    parameter Boolean allowFlowReversal=system.allowFlowReversal
      "= true to allow flow reversal, false restricts to design direction"
      annotation(Evaluate=true);
    parameter Boolean use_in_p0 = false "Use connector input for the pressure" annotation(Dialog(group="External inputs"), choices(checkBox=true));
    parameter Boolean use_in_T = false
      "Use connector input for the temperature"
      annotation(Dialog(group="External inputs"), choices(checkBox=true));
    parameter Boolean use_in_h = false
      "Use connector input for the specific enthalpy" annotation(Dialog(group="External inputs"), choices(checkBox=true));
    outer ThermoPower.System system "System wide properties";
    Medium.AbsolutePressure p "Actual pressure";
    FlangeB flange(redeclare package Medium = Medium) annotation (
       Placement(transformation(extent={{80,-20},{120,20}}, rotation=0)));
    Modelica.Blocks.Interfaces.RealInput in_p0 if use_in_p0 annotation (Placement(
          transformation(
          origin={-40,92},
          extent={{-20,-20},{20,20}},
          rotation=270), iconTransformation(
          extent={{-16,-16},{16,16}},
          rotation=270,
          origin={-40,84})));
    Modelica.Blocks.Interfaces.RealInput in_T if use_in_T
      "Externally supplied temperature" annotation (Placement(transformation(
          origin={0,60},
          extent={{-20,-20},{20,20}},
          rotation=270), iconTransformation(
          extent={{-16,-16},{16,16}},
          rotation=270,
          origin={0,96})));
    Modelica.Blocks.Interfaces.RealInput in_h if use_in_h annotation (Placement(
          transformation(
          origin={40,90},
          extent={{-20,-20},{20,20}},
          rotation=270), iconTransformation(
          extent={{-16,-16},{16,16}},
          rotation=270,
          origin={42,84})));
  protected
    Modelica.Blocks.Interfaces.RealInput in_p0_internal;
    Modelica.Blocks.Interfaces.RealInput in_T_internal;
    Modelica.Blocks.Interfaces.RealInput in_h_internal;
  equation
    if R > 0 then
      flange.p = p + flange.m_flow*R;
    else
      flange.p = p;
    end if;

    p = in_p0_internal;
    if not use_in_p0 then
      in_p0_internal = p0 "Pressure set by parameter";
    end if;

    if use_T then
      flange.h_outflow = Medium.specificEnthalpy_pTX(flange.p, in_T_internal, fill(0,0));
    else
      flange.h_outflow = in_h_internal "Enthalpy set by connector";
    end if;

    if not use_in_T then
      in_T_internal = T "Temperature set by parameter";
    end if;
    if not use_in_h then
      in_h_internal = h "Enthalpy set by parameter";
    end if;

    // Connect protected connectors to public conditional connectors
    connect(in_p0, in_p0_internal);
    connect(in_T, in_T_internal);
    connect(in_h, in_h_internal);

    // Restrictions on modelling options
    assert(not (use_in_T and use_in_h), "Either temperature or specific enthalpy input");
    assert(not (use_T and use_in_h), "use_in_h required use_T = false");
    assert(not (not use_T and use_in_T), "use_in_T required use_T = true");
    annotation (
      Documentation(info="<HTML>
<p><b>Modelling options</b></p>
<p>If <tt>R</tt> is set to zero, the pressure source is ideal; otherwise, the outlet pressure decreases proportionally to the outgoing flowrate.</p>
<p>If <code>use_T</code> is false, the specific enthalpy is prescribed, otherwise the temperature is prescribed.</p>
<p>The pressure, specific enthalpy and temperature can be supplied from external inputs by setting to true the corresponding <code>use_in_XX</code> parameter and connecting an external signal to the input connector.</p>
</HTML>", revisions="<html>
<ul>
<li><i>09 Oct 2017</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
    Restructured and added temperature input.</li>
<li><i>1 Oct 2003</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       First release.</li>
</ul>
</html>"));
  end SourcePressure;

  model SinkPressure "Pressure sink for water/steam flows"
    extends Icons.Water.SourceP;
    replaceable package Medium = StandardWater constrainedby
      Modelica.Media.Interfaces.PartialMedium "Medium model"
      annotation(choicesAllMatching = true);
    type HydraulicResistance = Real (
       final quantity="HydraulicResistance", final unit="Pa/(kg/s)");
    parameter Medium.AbsolutePressure p0=1.01325e5 "Nominal pressure";
    parameter Units.HydraulicResistance R=0 "Hydraulic resistance"
      annotation (Evaluate=true);
    parameter Boolean use_T = false "Use the temperature if true, otherwise use specific enthalpy";
    parameter Medium.Temperature T = 298.15 "Nominal temperature"
      annotation(Dialog(enable = use_T and not use_in_T));
    parameter Medium.SpecificEnthalpy h=1e5 "Nominal specific enthalpy"
      annotation(Dialog(enable = not use_T and not use_in_h));
    parameter Boolean allowFlowReversal=system.allowFlowReversal
      "= true to allow flow reversal, false restricts to design direction"
      annotation(Evaluate=true);
    parameter Boolean use_in_p0 = false "Use connector input for the pressure" annotation(Dialog(group="External inputs"), choices(checkBox=true));
    parameter Boolean use_in_T = false
      "Use connector input for the temperature"
      annotation(Dialog(group="External inputs"), choices(checkBox=true));
    parameter Boolean use_in_h = false
      "Use connector input for the specific enthalpy" annotation(Dialog(group="External inputs"), choices(checkBox=true));
    outer ThermoPower.System system "System wide properties";
    Medium.AbsolutePressure p "Actual pressure";
    FlangeA flange(redeclare package Medium = Medium, m_flow(min=if
            allowFlowReversal then -Modelica.Constants.inf else 0)) annotation (
       Placement(transformation(extent={{-120,-20},{-80,20}}, rotation=0)));
    Modelica.Blocks.Interfaces.RealInput in_p0 if use_in_p0 annotation (Placement(
          transformation(
          origin={-40,92},
          extent={{-20,-20},{20,20}},
          rotation=270), iconTransformation(
          extent={{-16,-16},{16,16}},
          rotation=270,
          origin={-40,84})));
    Modelica.Blocks.Interfaces.RealInput in_T if use_in_T
      "Externally supplied temperature" annotation (Placement(transformation(
          origin={0,60},
          extent={{-20,-20},{20,20}},
          rotation=270), iconTransformation(
          extent={{-16,-16},{16,16}},
          rotation=270,
          origin={0,96})));
    Modelica.Blocks.Interfaces.RealInput in_h if use_in_h annotation (Placement(
          transformation(
          origin={40,90},
          extent={{-20,-20},{20,20}},
          rotation=270), iconTransformation(
          extent={{-16,-16},{16,16}},
          rotation=270,
          origin={42,84})));
  protected
    Modelica.Blocks.Interfaces.RealInput in_p0_internal;
    Modelica.Blocks.Interfaces.RealInput in_T_internal;
    Modelica.Blocks.Interfaces.RealInput in_h_internal;

  equation
    if R > 0 then
      flange.p = p + flange.m_flow*R;
    else
      flange.p = p;
    end if;

    p = in_p0_internal;
    if not use_in_p0 then
      in_p0_internal = p0 "Pressure set by parameter";
    end if;

    if use_T then
      flange.h_outflow = Medium.specificEnthalpy_pTX(flange.p, in_T_internal, fill(0,0));
    else
      flange.h_outflow = in_h_internal "Enthalpy set by connector";
    end if;

    if not use_in_T then
      in_T_internal = T "Temperature set by parameter";
    end if;
    if not use_in_h then
      in_h_internal = h "Enthalpy set by parameter";
    end if;

    // Connect protected connectors to public conditional connectors
    connect(in_p0, in_p0_internal);
    connect(in_T, in_T_internal);
    connect(in_h, in_h_internal);

    // Restrictions on modelling options
    assert(not (use_in_T and use_in_h), "Either temperature or specific enthalpy input");
    assert(not (use_T and use_in_h), "use_in_h required use_T = false");
    assert(not (not use_T and use_in_T), "use_in_T required use_T = true");
    annotation (
      Diagram(graphics),
      Documentation(info="<HTML>
<p><b>Modelling options</b></p>
<p>If <tt>R</tt> is set to zero, the pressure sink is ideal; otherwise, the inlet pressure increases proportionally to the incoming flowrate.</p>
<p>If <code>use_T</code> is false, the specific enthalpy is prescribed, otherwise the temperature is prescribed.</p>
<p>The pressure, specific enthalpy and temperature can be supplied from external inputs by setting to true the corresponding <code>use_in_XX</code> parameter and connecting an external signal to the input connector.</p>
</HTML>", revisions="<html>
<ul>
<li><i>09 Oct 2017</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
    Restructured and added temperature input.</li>
<li><i>1 Oct 2003</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       First release.</li>
</ul>
</html>"));
  end SinkPressure;

  model SourceMassFlow "Flowrate source for water/steam flows"
    extends Icons.Water.SourceW;
    replaceable package Medium = StandardWater constrainedby
      Modelica.Media.Interfaces.PartialMedium "Medium model"
      annotation(choicesAllMatching = true);
    parameter Medium.MassFlowRate w0=0 "Nominal mass flowrate";
    parameter Medium.AbsolutePressure p0=1e5 "Nominal pressure";
    parameter Units.HydraulicConductance G=0 "Hydraulic conductance";
    parameter Boolean use_T = false "Use the temperature if true, otherwise use specific enthalpy";
    parameter Medium.Temperature T = 298.15 "Nominal temperature"
      annotation(Dialog(enable = use_T and not use_in_T));
    parameter Medium.SpecificEnthalpy h=1e5 "Nominal specific enthalpy"
      annotation(Dialog(enable = not use_T and not use_in_h));
    parameter Boolean allowFlowReversal=system.allowFlowReversal
      "= true to allow flow reversal, false restricts to design direction"
      annotation(Evaluate=true);
    parameter Boolean use_in_w0 = false "Use connector input for the mass flow"
      annotation(Dialog(group="External inputs"), choices(checkBox=true));
    parameter Boolean use_in_T = false
      "Use connector input for the temperature"
      annotation(Dialog(group="External inputs"), choices(checkBox=true));
    parameter Boolean use_in_h = false
      "Use connector input for the specific enthalpy"
      annotation(Dialog(group="External inputs"), choices(checkBox=true));
    outer ThermoPower.System system "System wide properties";
    Medium.MassFlowRate w "Mass flow rate";
    FlangeB flange(redeclare package Medium = Medium) annotation (
       Placement(transformation(extent={{80,-20},{120,20}}, rotation=0)));
    Modelica.Blocks.Interfaces.RealInput in_w0 if use_in_w0
      "Externally supplied mass flow rate"                  annotation (Placement(
          transformation(
          origin={-40,60},
          extent={{-20,-20},{20,20}},
          rotation=270), iconTransformation(
          extent={{-16,-16},{16,16}},
          rotation=270,
          origin={-40,56})));
    Modelica.Blocks.Interfaces.RealInput in_T if use_in_T
      "Externally supplied temperature" annotation (Placement(transformation(
          origin={0,60},
          extent={{-20,-20},{20,20}},
          rotation=270), iconTransformation(
          extent={{-16,-16},{16,16}},
          rotation=270,
          origin={6,56})));
    Modelica.Blocks.Interfaces.RealInput in_h if use_in_h
      "Externally supplied specific enthalpy" annotation (Placement(
          transformation(
          origin={40,60},
          extent={{-20,-20},{20,20}},
          rotation=270), iconTransformation(
          extent={{-16,-16},{16,16}},
          rotation=270,
          origin={52,56})));
  protected
    Modelica.Blocks.Interfaces.RealInput in_w0_internal;
    Modelica.Blocks.Interfaces.RealInput in_T_internal;
    Modelica.Blocks.Interfaces.RealInput in_h_internal;
  equation
    if G > 0 then
      flange.m_flow = -w + (flange.p - p0)*G;
    else
      flange.m_flow = -w;
    end if;

    w = in_w0_internal;
    if not use_in_w0 then
      in_w0_internal = w0 "Flow rate set by parameter";
    end if;

    if use_T then
      flange.h_outflow = Medium.specificEnthalpy_pTX(flange.p, in_T_internal, fill(0,0));
    else
      flange.h_outflow = in_h_internal "Enthalpy set by connector";
    end if;

    if not use_in_T then
      in_T_internal = T "Temperature set by parameter";
    end if;
    if not use_in_h then
      in_h_internal = h "Enthalpy set by parameter";
    end if;

    // Connect protected connectors to public conditional connectors
    connect(in_w0, in_w0_internal);
    connect(in_h, in_h_internal);
    connect(in_T, in_T_internal);

    // Restrictions on modelling options
    assert(not (use_in_T and use_in_h), "Either temperature or specific enthalpy input");
    assert(not (use_T and use_in_h), "use_in_h required use_T = false");
    assert(not (not use_T and use_in_T), "use_in_T required use_T = true");
    annotation (
      Documentation(info="<HTML>
<p><b>Modelling options</b></p>
<p>If <code>G</code> is set to zero, the flowrate source is ideal; otherwise, the outgoing flowrate decreases proportionally to the outlet pressure.</p>
<p>If <code>use_T</code> is false, the specific enthalpy is prescribed, otherwise the temperature is prescribed.</p>
<p>The mass flow rate, specific enthalpy and temperature can be supplied from external inputs by setting to true the corresponding <code>use_in_XX</code> parameter and connecting an external signal to the input connector.</p>
</HTML>", revisions="<html>
<ul>
<li><i>09 Oct 2017</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
    Restructured and added temperature input.</li>
<li><i>1 Oct 2003</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       First release.</li>
</ul>
</html>"));
  end SourceMassFlow;

  model SinkMassFlow "Flowrate sink for water/steam flows"
    extends Icons.Water.SourceW;
    replaceable package Medium = StandardWater constrainedby
      Modelica.Media.Interfaces.PartialMedium "Medium model"
      annotation(choicesAllMatching = true);
    parameter Medium.MassFlowRate w0=0 "Nominal mass flowrate";
    parameter Medium.AbsolutePressure p0=1e5 "Nominal pressure";
    parameter Units.HydraulicConductance G=0 "Hydraulic conductance";
    parameter Boolean use_T = false "Use the temperature if true, otherwise use specific enthalpy";
    parameter Medium.Temperature T = 298.15 "Nominal temperature"
      annotation(Dialog(enable = use_T and not use_in_T));
    parameter Medium.SpecificEnthalpy h=1e5 "Nominal specific enthalpy"
      annotation(Dialog(enable = not use_T and not use_in_h));
    parameter Boolean allowFlowReversal=system.allowFlowReversal
      "= true to allow flow reversal, false restricts to design direction"
      annotation(Evaluate=true);
    parameter Boolean use_in_w0 = false "Use connector input for the mass flow"
      annotation(Dialog(group="External inputs"), choices(checkBox=true));
    parameter Boolean use_in_T = false
      "Use connector input for the temperature"
      annotation(Dialog(group="External inputs"), choices(checkBox=true));
    parameter Boolean use_in_h = false
      "Use connector input for the specific enthalpy"
      annotation(Dialog(group="External inputs"), choices(checkBox=true));
    outer ThermoPower.System system "System wide properties";
    Medium.MassFlowRate w "Mass flow rate";
    FlangeA flange(
      redeclare package Medium = Medium,
      m_flow(min = if allowFlowReversal then -Modelica.Constants.inf else 0)) annotation (
       Placement(transformation(extent={{-120,-20},{-80,20}},
                                                            rotation=0),
          iconTransformation(extent={{-120,-20},{-80,20}})));
    Modelica.Blocks.Interfaces.RealInput in_w0 if use_in_w0
      "Externally supplied mass flow rate"                  annotation (Placement(
          transformation(
          origin={-40,60},
          extent={{-20,-20},{20,20}},
          rotation=270), iconTransformation(
          extent={{-16,-16},{16,16}},
          rotation=270,
          origin={-40,56})));
    Modelica.Blocks.Interfaces.RealInput in_T if use_in_T
      "Externally supplied temperature" annotation (Placement(transformation(
          origin={0,60},
          extent={{-20,-20},{20,20}},
          rotation=270), iconTransformation(
          extent={{-16,-16},{16,16}},
          rotation=270,
          origin={6,56})));
    Modelica.Blocks.Interfaces.RealInput in_h if use_in_h
      "Externally supplied specific enthalpy" annotation (Placement(
          transformation(
          origin={40,60},
          extent={{-20,-20},{20,20}},
          rotation=270), iconTransformation(
          extent={{-16,-16},{16,16}},
          rotation=270,
          origin={52,56})));
  protected
    Modelica.Blocks.Interfaces.RealInput in_w0_internal;
    Modelica.Blocks.Interfaces.RealInput in_T_internal;
    Modelica.Blocks.Interfaces.RealInput in_h_internal;
  equation
    if G > 0 then
      flange.m_flow = w + (flange.p - p0)*G;
    else
      flange.m_flow = w;
    end if;

    w = in_w0_internal;
    if not use_in_w0 then
      in_w0_internal = w0 "Flow rate set by parameter";
    end if;

    if use_T then
      flange.h_outflow = Medium.specificEnthalpy_pTX(flange.p, in_T_internal, fill(0,0));
    else
      flange.h_outflow = in_h_internal "Enthalpy set by connector";
    end if;

    if not use_in_T then
      in_T_internal = T "Temperature set by parameter";
    end if;
    if not use_in_h then
      in_h_internal = h "Enthalpy set by parameter";
    end if;

    // Connect protected connectors to public conditional connectors
    connect(in_w0, in_w0_internal);
    connect(in_h, in_h_internal);
    connect(in_T, in_T_internal);

    // Restrictions on modelling options
    assert(not (use_in_T and use_in_h), "Either temperature or specific enthalpy input");
    assert(not (use_T and use_in_h), "use_in_h required use_T = false");
    assert(not (not use_T and use_in_T), "use_in_T required use_T = true");
    annotation (
      Documentation(info="<HTML>
<p><b>Modelling options</b></p>
<p>If <tt>G</tt> is set to zero, the flowrate source is ideal; otherwise, the outgoing flowrate increases proportionally to the inlet pressure.</p>
<p>If <code>use_T</code> is false, the specific enthalpy is prescribed, otherwise the temperature is prescribed.</p>
<p>The mass flow rate, specific enthalpy and temperature can be supplied from external inputs by setting to true the corresponding <code>use_in_XX</code> parameter and connecting an external signal to the input connector.</p>
</HTML>", revisions="<html>
<ul>
<li><i>09 Oct 2017</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
    Restructured and added temperature input.</li>
<li><i>1 Oct 2003</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       First release.</li>
</ul>
</html>"));
  end SinkMassFlow;

  model ThroughMassFlow "Prescribes the flow rate across the component"
    extends Icons.Water.SourceW;
    replaceable package Medium = StandardWater constrainedby
      Modelica.Media.Interfaces.PartialMedium "Medium model"
      annotation(choicesAllMatching = true);
    parameter Medium.MassFlowRate w0=0 "Nominal mass flow rate";
    parameter Boolean allowFlowReversal=system.allowFlowReversal
      "= true to allow flow reversal, false restricts to design direction"
      annotation(Evaluate=true);
    parameter Boolean use_in_w0 = false "Use connector input for the mass flow" annotation(Dialog(group="External inputs"), choices(checkBox=true));
    outer ThermoPower.System system "System wide properties";
    Medium.MassFlowRate w "Mass flow rate";
    FlangeA inlet(redeclare package Medium = Medium, m_flow(min=if
            allowFlowReversal then -Modelica.Constants.inf else 0)) annotation (
       Placement(transformation(extent={{-120,-20},{-80,20}}, rotation=0)));
    FlangeB outlet(redeclare package Medium = Medium, m_flow(max=if
            allowFlowReversal then +Modelica.Constants.inf else 0)) annotation (
       Placement(transformation(extent={{80,-20},{120,20}}, rotation=0)));
    Modelica.Blocks.Interfaces.RealInput in_w0 if use_in_w0 annotation (Placement(
          transformation(
          origin={-40,60},
          extent={{-20,-20},{20,20}},
          rotation=270)));
  protected
    Modelica.Blocks.Interfaces.RealInput in_w0_internal;

  equation
    inlet.m_flow + outlet.m_flow = 0 "Mass balance";
    inlet.m_flow = w "Flow characteristics";

    w = in_w0_internal;
    if not use_in_w0 then
      in_w0_internal = w0 "Flow rate set by parameter";
    end if;

    // Energy balance
    inlet.h_outflow = inStream(outlet.h_outflow);
    inStream(inlet.h_outflow) = outlet.h_outflow;

    // Connect protected connectors to public conditional connectors
    connect(in_w0, in_w0_internal);

    annotation (
      Icon(graphics={Text(extent={{-98,72},{-48,40}}, textString="w0")}),
      Documentation(info="<HTML>
This component prescribes the flow rate passing through it. The change of
specific enthalpy due to the pressure difference between the inlet and the
outlet is ignored; use <t>Pump</t> models if this has to be taken into account correctly.
<p><b>Modelling options</b></p>
<p>If <tt>w0Fix</tt> is set to true, the flowrate is given by the parameter <tt>w0</tt>; otherwise, the <tt>in_w0</tt> connector must be wired, providing the (possibly varying) flowrate value.</p>
</HTML>", revisions="<html>
<ul>
<li><i>18 Mar 2005</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       First release.</li>
</ul>
</html>"),
      Diagram(graphics));
  end ThroughMassFlow;

  model PressDropLin "Linear pressure drop for water/steam flows"
    extends Icons.Water.PressDrop;
    replaceable package Medium = StandardWater constrainedby
      Modelica.Media.Interfaces.PartialMedium "Medium model"
      annotation(choicesAllMatching = true);
    parameter Units.HydraulicResistance R "Hydraulic resistance";
    parameter Boolean allowFlowReversal=system.allowFlowReversal
      "= true to allow flow reversal, false restricts to design direction"
      annotation(Evaluate=true);
    outer ThermoPower.System system "System wide properties";
    FlangeA inlet(redeclare package Medium = Medium, m_flow(min=if
            allowFlowReversal then -Modelica.Constants.inf else 0)) annotation (
       Placement(transformation(extent={{-120,-20},{-80,20}}, rotation=0)));
    FlangeB outlet(redeclare package Medium = Medium, m_flow(max=if
            allowFlowReversal then +Modelica.Constants.inf else 0)) annotation (
       Placement(transformation(extent={{80,-20},{120,20}}, rotation=0)));
  equation
    inlet.m_flow + outlet.m_flow = 0;
    inlet.p - outlet.p = R*inlet.m_flow "Flow characteristics";
    // Energy balance
    inlet.h_outflow = inStream(outlet.h_outflow);
    inStream(inlet.h_outflow) = outlet.h_outflow;
    annotation (
      Icon(graphics={Text(extent={{-100,-44},{100,-76}}, textString="%name")}),
      Documentation(info="<HTML>
<p>This very simple model provides a pressure drop which is proportional to the flowrate, without computing any fluid property.</p>
</HTML>", revisions="<html>
<ul>
<li><i>16 Dec 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Medium model and standard medium definition added.</li>
<li><i>1 Oct 2003</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       First release.</li>
</ul>
</html>
"),   Diagram(graphics));
  end PressDropLin;

  model PressDrop "Pressure drop for water/steam flows"
    extends Icons.Water.PressDrop;
    import ThermoPower.Choices.PressDrop.FFtypes;
    replaceable package Medium = StandardWater constrainedby
      Modelica.Media.Interfaces.PartialMedium "Medium model"
      annotation(choicesAllMatching = true);
    Medium.ThermodynamicState state "Thermodynamic state of the fluid";
    parameter Medium.MassFlowRate wnom "Nominal mass flowrate";
    parameter FFtypes FFtype=FFtypes.Kf "Friction Factor Type";
    parameter Real Kf = 0 "Hydraulic resistance coefficient (DP = Kf*w^2/rho)"
      annotation(Dialog(enable = (FFtype == ThermoPower.Choices.PressDrop.FFtypes.Kf)));
    parameter SI.PressureDifference dpnom "Nominal pressure drop";
    parameter Medium.Density rhonom=0 "Nominal density"
      annotation(Dialog(enable = (FFtype == ThermoPower.Choices.PressDrop.FFtypes.OpPoint)));
    parameter Real K=0 "Kinetic resistance coefficient (DP=K*rho*velocity2/2)";
    parameter SI.Area A=0 "Cross-section";
    parameter SI.PerUnit wnf=0.01
      "Fraction of nominal flow rate at which linear friction equals turbulent friction";
    parameter SI.PerUnit Kfc=1 "Friction factor correction coefficient";
    final parameter Real Kf_a(fixed = false)
      "Actual hydraulic resistance coefficient";
    parameter Boolean allowFlowReversal=system.allowFlowReversal
      "= true to allow flow reversal, false restricts to design direction"
      annotation(Evaluate=true);
    outer ThermoPower.System system "System wide properties";
    function squareReg = ThermoPower.Functions.squareReg;
    Medium.Density rho "Fluid density";
    Medium.MassFlowRate w "Flow rate at the inlet";
    Medium.AbsolutePressure pin "Inlet pressure";
    Medium.AbsolutePressure pout "Outlet pressure";
    SI.PressureDifference dp "Pressure drop";
    FlangeA inlet(m_flow(start=wnom, min=if allowFlowReversal then -Modelica.Constants.inf
             else 0), redeclare package Medium = Medium) annotation (Placement(
          transformation(extent={{-120,-20},{-80,20}}, rotation=0)));
    FlangeB outlet(m_flow(start=-wnom, max=if allowFlowReversal then +Modelica.Constants.inf
             else 0), redeclare package Medium = Medium) annotation (Placement(
          transformation(extent={{80,-20},{120,20}}, rotation=0)));
  initial equation
    if FFtype == FFtypes.Kf then
      Kf_a = Kf*Kfc;
    elseif FFtype == FFtypes.OpPoint then
      Kf_a = dpnom*rhonom/wnom^2*Kfc;
    elseif FFtype == FFtypes.Kinetic then
      Kf_a = K/(2*A^2)*Kfc;
    else
      Kf_a = 0;
      assert(false, "Unsupported FFtype");
    end if;
  equation
    assert(dpnom > 0, "Please set a positive value for dpnom");
    assert(rhonom > 0 or FFtype <> FFtypes.OpPoint, "Please set a positive value for rhonom");
    // Fluid properties
  /*
  if not allowFlowReversal then
    state = Medium.setState_phX(inlet.p, inStream(inlet.h_outflow));
  else
    state = Medium.setSmoothState(
        w,
        Medium.setState_phX(inlet.p, inStream(inlet.h_outflow)),
        Medium.setState_phX(outlet.p, inStream(outlet.h_outflow)),
        wnom*wnf);
  end if;
  */
    state = Medium.setState_phX(inlet.p, inStream(inlet.h_outflow));

    rho = Medium.density(state) "Fluid density";
    pin - pout = homotopy(smooth(1, Kf_a*squareReg(w, wnom*wnf))/rho,
                                 dpnom/wnom*w) "Flow characteristics";
    inlet.m_flow + outlet.m_flow = 0 "Mass  balance";
    // Energy balance
    inlet.h_outflow = inStream(outlet.h_outflow);
    inStream(inlet.h_outflow) = outlet.h_outflow;
    //Boundary conditions
    w = inlet.m_flow;
    pin = inlet.p;
    pout = outlet.p;
    dp = pin - pout;
      annotation(Dialog(enable = (FFtype == ThermoPower.Choices.PressDrop.FFtypes.Kinetic)),
                 Dialog(enable = (FFtype == ThermoPower.Choices.PressDrop.FFtypes.Kinetic)),
      Icon(graphics={Text(extent={{-100,-50},{100,-82}}, textString="%name")}),
      Documentation(info="<HTML>
<p>The pressure drop across the inlet and outlet connectors is computed according to a turbulent friction model, i.e. is proportional to the squared velocity of the fluid. The friction coefficient can be specified directly, or by giving an operating point, or as a multiple of the kinetic pressure. In the latter two cases, the correction coefficient <tt>Kfc</tt> can be used to modify the friction coefficient, e.g. to fit some experimental operating point.</p>
<p>A small linear pressure drop is added to avoid numerical singularities at low or zero flowrate. The <tt>wnom</tt> parameter must be always specified; the additional linear pressure drop is such that it is equal to the turbulent pressure drop when the flowrate is equal to <tt>wnf*wnom</tt> (the default value is 1% of the nominal flowrate).
<p><b>Modelling options</b></p>
<p>The following options are available to specify the friction coefficient:
<ul><li><tt>FFtype = 0</tt>: the hydraulic friction coefficient <tt>Kf</tt> is set directly.</li>
<li><tt>FFtype = 1</tt>: the hydraulic friction coefficient is specified by the nominal operating point (<tt>wnom</tt>,<tt>dpnom</tt>, <tt>rhonom</tt>).</li>
<li><tt>FFtype = 2</tt>: the pressure drop is <tt>K</tt> times the kinetic pressure.</li></ul>
</HTML>", revisions="<html>
<ul>
<li><i>16 Dec 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Standard medium definition added.</li>
<li><i>18 Nov 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       <tt>Kfnom</tt> removed, <tt>Kf</tt> can now be set directly.</li>
<li><i>18 Jun 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Adapted to Modelica.Media.</li>
<li><i>1 Oct 2003</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       First release.</li>
</ul>
</html>
"),   Diagram(graphics));
  end PressDrop;

  model Header "Header with metal walls for water/steam flows"
    extends Icons.Water.Header;
    replaceable package Medium = StandardWater constrainedby
      Modelica.Media.Interfaces.PartialMedium "Medium model"
      annotation(choicesAllMatching = true);
    Medium.ThermodynamicState fluidState "Thermodynamic state of the fluid";
    parameter SI.Volume V "Inner volume";
    parameter SI.Area S=0 "Internal surface";
    parameter SI.Position H=0 "Elevation of outlet over inlet"
      annotation (Evaluate=true);
    parameter SI.CoefficientOfHeatTransfer gamma=0 "Heat Transfer Coefficient"
      annotation (Evaluate=true);
    parameter SI.HeatCapacity Cm=0 "Metal Heat Capacity" annotation (Evaluate=true);
    parameter Boolean allowFlowReversal=system.allowFlowReversal
      "= true to allow flow reversal, false restricts to design direction"
      annotation(Evaluate=true);
    outer ThermoPower.System system "System wide properties";
    parameter Choices.FluidPhase.FluidPhases FluidPhaseStart=Choices.FluidPhase.FluidPhases.Liquid
      "Fluid phase (only for initialization!)"
      annotation (Dialog(tab="Initialisation"));
    parameter Medium.AbsolutePressure pstart "Pressure start value"
      annotation (Dialog(tab="Initialisation"));
    parameter Medium.SpecificEnthalpy hstart=if FluidPhaseStart == Choices.FluidPhase.FluidPhases.Liquid
         then 1e5 else if FluidPhaseStart == Choices.FluidPhase.FluidPhases.Steam
         then 3e6 else 1e6 "Specific enthalpy start value"
      annotation (Dialog(tab="Initialisation"));
    parameter Medium.Temperature Tmstart=300
      "Metal wall temperature start value"
      annotation (Dialog(tab="Initialisation"));
    parameter Choices.Init.Options initOpt=system.initOpt
      "Initialisation option"
      annotation (Dialog(tab="Initialisation"));
    parameter Boolean noInitialPressure=false
      "Remove initial equation on pressure"
      annotation (Dialog(tab="Initialisation"),choices(checkBox=true));
    parameter Boolean noInitialEnthalpy=false
      "Remove initial equation on enthalpy"
      annotation (Dialog(tab="Initialisation"),choices(checkBox=true));

    FlangeA inlet(
      h_outflow(start=hstart),
      redeclare package Medium = Medium,
      m_flow(min=if allowFlowReversal then -Modelica.Constants.inf else 0))
      annotation (Placement(transformation(extent={{-122,-20},{-80,20}},
            rotation=0)));
    FlangeB outlet(
      h_outflow(start=hstart),
      redeclare package Medium = Medium,
      m_flow(max=if allowFlowReversal then +Modelica.Constants.inf else 0))
      annotation (Placement(transformation(extent={{80,-20},{120,20}}, rotation=
             0)));
    Medium.AbsolutePressure p(start=pstart, stateSelect=if Medium.singleState then StateSelect.avoid
           else StateSelect.prefer) "Fluid pressure at the outlet";
    Medium.SpecificEnthalpy h(start=hstart, stateSelect=StateSelect.prefer)
      "Fluid specific enthalpy";
    Medium.SpecificEnthalpy hi "Inlet specific enthalpy";
    Medium.SpecificEnthalpy ho "Outlet specific enthalpy";
    SI.Mass M "Fluid mass";
    SI.Energy E "Fluid energy";
    Medium.Temperature T "Fluid temperature";
    Medium.Temperature Tm(start=Tmstart) "Wall temperature";
    SI.Time Tr "Residence time";
    Real dM_dt;
    Real dE_dt;
    replaceable Thermal.HT thermalPort "Internal surface of metal wall"
      annotation (Dialog(enable=false), Placement(transformation(extent={{-24,
              50},{24,64}}, rotation=0)));
  equation
    // Set fluid properties
    fluidState = Medium.setState_phX(p, h);
    T = Medium.temperature(fluidState);

    M = V*Medium.density(fluidState) "Fluid mass";
    E = M*h - p*V "Fluid energy";
    dM_dt = V*(Medium.density_derp_h(fluidState)*der(p) + Medium.density_derh_p(
      fluidState)*der(h));
    dE_dt = h*dM_dt + M*der(h) - V*der(p);
    dM_dt = inlet.m_flow + outlet.m_flow "Fluid mass balance";
    dE_dt = inlet.m_flow*hi + outlet.m_flow*ho + gamma*S*(Tm - T) + thermalPort.Q_flow
      "Fluid energy balance";
    if Cm > 0 and gamma > 0 then
      Cm*der(Tm) = gamma*S*(T - Tm) "Energy balance of the built-in wall model";
    else
      Tm = T "Trivial equation for metal temperature";
    end if;

    // Boundary conditions
    hi = homotopy(if not allowFlowReversal then inStream(inlet.h_outflow) else
      actualStream(inlet.h_outflow), inStream(inlet.h_outflow));
    ho = homotopy(if not allowFlowReversal then h else actualStream(outlet.h_outflow),
      h);
    inlet.h_outflow = h;
    outlet.h_outflow = h;
    inlet.p = p + Medium.density(fluidState)*Modelica.Constants.g_n*H;
    outlet.p = p;
    thermalPort.T = T;

    Tr = noEvent(M/max(abs(inlet.m_flow), Modelica.Constants.eps))
      "Residence time";
  initial equation
    // Initial conditions
    if initOpt == Choices.Init.Options.noInit then
      // do nothing
    elseif initOpt == Choices.Init.Options.fixedState then
      if not noInitialPressure then
        p = pstart;
      end if;
      if not noInitialEnthalpy then
        h = hstart;
      end if;
      if (Cm > 0 and gamma > 0) then
        Tm = Tmstart;
      end if;
    elseif initOpt == Choices.Init.Options.steadyState then
      if not noInitialEnthalpy then
        der(h) = 0;
      end if;
      if (not Medium.singleState and not noInitialPressure) then
        der(p) = 0;
      end if;
      if (Cm > 0 and gamma > 0) then
        der(Tm) = 0;
      end if;
    elseif initOpt == Choices.Init.Options.steadyStateNoP then
      if not noInitialEnthalpy then
        der(h) = 0;
      end if;
      if (Cm > 0 and gamma > 0) then
        der(Tm) = 0;
      end if;
    else
      assert(false, "Unsupported initialisation option");
    end if;
    annotation (
      Icon(graphics),
      Documentation(info="<HTML>
<p>This model describes a constant volume header with metal walls. The fluid can be water, steam, or a two-phase mixture.
<p>It is possible to take into account the heat storage and transfer in the metal wall in two ways:
<ul>
<li>
  Leave <tt>InternalSurface</tt> unconnected, and set the appropriate
  values for the total wall heat capacity <tt>Cm</tt>, surface <tt>S</tt>
  and heat transfer coefficient <tt>gamma</tt>. In this case, the metal
  wall temperature is considered as uniform, and the wall is thermally
  insulated from the outside.
</li>
<li>
  Set <tt>Cm = 0</tt>, and connect a suitable thermal model of the the
  wall to the <tt>InternalSurface</tt> connector instead. This can be
  useful in case a more detailed thermal model is needed, e.g. for
  thermal stress studies.
</li>
</ul>
<p>The model can represent an actual header when connected to the model of a bank of tubes (e.g., <tt>Flow1D</tt> with <tt>Nt>1</tt>).</p>
</HTML>", revisions="<html>
<ul>
<li><i>30 May 2005</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Initialisation support added.</li>
<li><i>12 Apr 2005</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       <tt>InternalSurface</tt> connector added.</li>
<li><i>16 Dec 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Standard medium definition added.</li>
<li><i>28 Jul 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Added head between inlet and outlet.</li>
<li><i>7 Jul 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Changed name from <tt>Collector</tt> to <tt>Header</tt>.</li>
<li><i>18 Jun 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Adapted to Modelica.Media.</li>
<li><i>1 Oct 2003</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       First release.</li>
</ul>
</html>
"),   Diagram(graphics));
  end Header;

  model Mixer "Mixer with metal walls for water/steam flows"
    extends Icons.Water.Mixer;
    replaceable package Medium = StandardWater constrainedby
      Modelica.Media.Interfaces.PartialMedium "Medium model"
      annotation(choicesAllMatching = true);
    Medium.ThermodynamicState fluidState "Thermodynamic state of the fluid";
    parameter SI.Volume V "Internal volume";
    parameter SI.Area S=0 "Internal surface";
    parameter SI.CoefficientOfHeatTransfer gamma=0
      "Internal Heat Transfer Coefficient" annotation (Evaluate=true);
    parameter SI.HeatCapacity Cm=0 "Metal Heat Capacity" annotation (Evaluate=true);
    parameter Boolean allowFlowReversal=system.allowFlowReversal
      "= true to allow flow reversal, false restricts to design direction"
      annotation(Evaluate=true);
    outer ThermoPower.System system "System wide properties";
    parameter Choices.FluidPhase.FluidPhases FluidPhaseStart=Choices.FluidPhase.FluidPhases.Liquid
      "Fluid phase (only for initialization!)"
      annotation (Dialog(tab="Initialisation"));
    parameter Medium.AbsolutePressure pstart "Pressure start value"
      annotation (Dialog(tab="Initialisation"));
    parameter Medium.SpecificEnthalpy hstart=if FluidPhaseStart == Choices.FluidPhase.FluidPhases.Liquid
         then 1e5 else if FluidPhaseStart == Choices.FluidPhase.FluidPhases.Steam
         then 3e6 else 1e6 "Specific enthalpy start value"
      annotation (Dialog(tab="Initialisation"));
    parameter Medium.Temperature Tmstart=300
      "Metal wall temperature start value"
      annotation (Dialog(tab="Initialisation"));
    parameter Choices.Init.Options initOpt=system.initOpt
      "Initialisation option"
      annotation (Dialog(tab="Initialisation"));
    parameter Boolean noInitialPressure=false
      "Remove initial equation on pressure"
      annotation (Dialog(tab="Initialisation"),choices(checkBox=true));
    parameter Boolean noInitialEnthalpy=false
      "Remove initial equation on enthalpy"
      annotation (Dialog(tab="Initialisation"),choices(checkBox=true));

    FlangeA in1(
      h_outflow(start=hstart),
      redeclare package Medium = Medium,
      m_flow(min=if allowFlowReversal then -Modelica.Constants.inf else 0))
      annotation (Placement(transformation(extent={{-100,40},{-60,80}},
            rotation=0)));
    FlangeA in2(
      h_outflow(start=hstart),
      redeclare package Medium = Medium,
      m_flow(min=if allowFlowReversal then -Modelica.Constants.inf else 0))
      annotation (Placement(transformation(extent={{-100,-80},{-60,-40}},
            rotation=0)));
    FlangeB out(
      h_outflow(start=hstart),
      redeclare package Medium = Medium,
      m_flow(max=if allowFlowReversal then +Modelica.Constants.inf else 0))
      annotation (Placement(transformation(extent={{80,-20},{120,20}}, rotation=
             0)));
    Medium.AbsolutePressure p(start=pstart, stateSelect=if Medium.singleState then StateSelect.avoid
           else StateSelect.prefer) "Fluid pressure";
    Medium.SpecificEnthalpy h(start=hstart, stateSelect=StateSelect.prefer)
      "Fluid specific enthalpy";
    Medium.SpecificEnthalpy hi1 "Inlet 1 specific enthalpy";
    Medium.SpecificEnthalpy hi2 "Inlet 2 specific enthalpy";
    Medium.SpecificEnthalpy ho "Outlet specific enthalpy";
    SI.Mass M "Fluid mass";
    SI.Energy E "Fluid energy";
    SI.HeatFlowRate Q "Heat flow rate exchanged with the outside";
    Medium.Temperature T "Fluid temperature";
    Medium.Temperature Tm(start=Tmstart) "Wall temperature";
    SI.Time Tr "Residence time";
    replaceable Thermal.HT thermalPort "Internal surface of metal wall"
      annotation (Placement(transformation(extent={{-24,66},{24,80}}, rotation=
              0)));
  equation
    // Set fluid properties
    fluidState = Medium.setState_phX(p, h);
    T = Medium.temperature(fluidState);

    M = V*Medium.density(fluidState) "Fluid mass";
    E = M*Medium.specificInternalEnergy(fluidState) "Fluid energy";
    der(M) = in1.m_flow + in2.m_flow + out.m_flow "Fluid mass balance";
    der(E) = in1.m_flow*hi1 + in2.m_flow*hi2 + out.m_flow*ho - gamma*S*(T - Tm)
       + Q "Fluid energy balance";
    if Cm > 0 and gamma > 0 then
      Cm*der(Tm) = gamma*S*(T - Tm) "Metal wall energy balance";
    else
      Tm = T;
    end if;

    // Boundary conditions
    hi1 = homotopy(if not allowFlowReversal then inStream(in1.h_outflow) else
      actualStream(in1.h_outflow), inStream(in1.h_outflow));
    hi2 = homotopy(if not allowFlowReversal then inStream(in2.h_outflow) else
      actualStream(in2.h_outflow), inStream(in2.h_outflow));
    ho = homotopy(if not allowFlowReversal then h else actualStream(out.h_outflow),
      h);
    in1.h_outflow = h;
    in2.h_outflow = h;
    out.h_outflow = h;
    in1.p = p;
    in2.p = p;
    out.p = p;
    thermalPort.Q_flow = Q;
    thermalPort.T = T;

    Tr = noEvent(M/max(abs(out.m_flow), Modelica.Constants.eps))
      "Residence time";

  initial equation
    // Initial conditions
    if initOpt == Choices.Init.Options.noInit then
      // do nothing
    elseif initOpt == Choices.Init.Options.fixedState then
      if not noInitialPressure then
        p = pstart;
      end if;
      if not noInitialEnthalpy then
        h = hstart;
      end if;
      if (Cm > 0 and gamma > 0) then
        Tm = Tmstart;
      end if;
    elseif initOpt == Choices.Init.Options.steadyState then
      if not noInitialEnthalpy then
        der(h) = 0;
      end if;
      if (not Medium.singleState and not noInitialPressure) then
        der(p) = 0;
      end if;
      if (Cm > 0 and gamma > 0) then
        der(Tm) = 0;
      end if;
    elseif initOpt == Choices.Init.Options.steadyStateNoP then
      if not noInitialEnthalpy then
        der(h) = 0;
      end if;
      if (Cm > 0 and gamma > 0) then
        der(Tm) = 0;
      end if;
    else
      assert(false, "Unsupported initialisation option");
    end if;

    annotation (
      Placement(transformation(extent={{80,-20},{120,20}}, rotation=0)),
      Documentation(info="<HTML>
<p>This model describes a constant volume mixer with metal walls. The fluid can be water, steam, or a two-phase mixture. The metal wall temperature and the heat transfer coefficient between the wall and the fluid are uniform. The wall is thermally insulated from the outside.
</HTML>", revisions="<html>
<ul>
<li><i>23 May 2008</i>
    by <a>Luca Savoldelli</a>:<br>
       Thermal port added.</li>
<li><i>30 May 2005</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Initialisation support added.</li>
<li><i>16 Dec 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Standard medium definition added.</li>
<li><i>18 Jun 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Adapted to Modelica.Media.</li>
<li><i>1 Oct 2003</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       First release.</li>
</ul>
</html>"),
      Icon(graphics),
      Diagram(graphics));
  end Mixer;

  model Tank "Open tank with free surface"
    extends Icons.Water.Tank;
    replaceable package Medium = StandardWater constrainedby
      Modelica.Media.Interfaces.PartialMedium "Medium model"
      annotation(choicesAllMatching = true);
    Medium.ThermodynamicState liquidState
      "Thermodynamic state of the liquid";
    parameter SI.Area A "Cross-sectional area";
    parameter SI.Volume V0=0 "Volume at zero level";
    parameter SI.Height y0 = 0 "Height of zero level over inlet and outlet flanges";
    parameter Boolean allowFlowReversal=system.allowFlowReversal
      "= true to allow flow reversal, false restricts to design direction"
      annotation(Evaluate=true);
    outer ThermoPower.System system "System wide properties";
    parameter SI.Length ystart "Start level"
      annotation (Dialog(tab="Initialisation"));
    parameter Medium.SpecificEnthalpy hstart=1e5
      annotation (Dialog(tab="Initialisation"));
    SI.Length y(start=ystart, stateSelect=StateSelect.prefer) "Level";
    SI.Volume V "Liquid volume";
    SI.Mass M "Liquid mass";
    SI.Enthalpy H "Liquid (total) enthalpy";
    Medium.SpecificEnthalpy h(start=hstart, stateSelect=StateSelect.prefer)
      "Liquid specific enthalpy";
    Medium.SpecificEnthalpy hin "Inlet specific enthalpy";
    Medium.SpecificEnthalpy htop "Top inlet specific enthalpy";
    Medium.SpecificEnthalpy hout "Outlet specific enthalpy";
    Medium.AbsolutePressure p(start=system.p_amb) "Bottom pressure";
    constant SI.Acceleration g=Modelica.Constants.g_n;
    FlangeA inlet(redeclare package Medium = Medium, m_flow(min=if
            allowFlowReversal then -Modelica.Constants.inf else 0)) annotation (
       Placement(transformation(extent={{-100,-80},{-60,-40}}, rotation=0)));
    FlangeA inletTop(redeclare package Medium = Medium, m_flow(min=0)) annotation (
       Placement(transformation(extent={{-100,-80},{-60,-40}}, rotation=0),
          iconTransformation(extent={{-20,60},{20,100}})));
    FlangeB outlet(redeclare package Medium = Medium, m_flow(max=if
            allowFlowReversal then +Modelica.Constants.inf else 0)) annotation (
       Placement(transformation(extent={{60,-80},{100,-40}}, rotation=0)));
    parameter Choices.Init.Options initOpt=system.initOpt
      "Initialisation option"
      annotation (Dialog(tab="Initialisation"));
    parameter Boolean noInitialPressure=false
      "Remove initial equation on pressure"
      annotation (Dialog(tab="Initialisation"),choices(checkBox=true));
  equation
    // Set liquid properties
    liquidState = Medium.setState_phX(system.p_amb, h);

    V = V0 + A*y "Liquid volume";
    M = V*Medium.density(liquidState) "Liquid mass";
    H = M*Medium.specificInternalEnergy(liquidState) "Liquid enthalpy";
    der(M) = inlet.m_flow + inletTop.m_flow + outlet.m_flow "Mass balance";
    der(H) = inlet.m_flow*hin + inletTop.m_flow*htop + outlet.m_flow*hout "Energy balance";
    p - system.p_amb = Medium.density(liquidState)*g*(y+y0) "Stevin's law";

    // Boundary conditions
    hin = homotopy(if not allowFlowReversal then inStream(inlet.h_outflow)
                     else actualStream(inlet.h_outflow), inStream(inlet.h_outflow));
    htop = inStream(inletTop.h_outflow);
    hout = homotopy(if not allowFlowReversal then h else actualStream(outlet.h_outflow),
      h);
    inlet.h_outflow = h;
    inletTop.h_outflow = h "dummy, not used";
    outlet.h_outflow = h;
    inlet.p = p;
    inletTop.p = system.p_amb;
    outlet.p = p;
  initial equation
    if initOpt == Choices.Init.Options.noInit then
      // do nothing
    elseif initOpt == Choices.Init.Options.fixedState then
      if not noInitialPressure then
        y = ystart;
      end if;
      h = hstart;
    elseif initOpt == Choices.Init.Options.steadyState then
      if not noInitialPressure then
        der(y) = 0;
      end if;
      der(h) = 0;
    else
      assert(false, "Unsupported initialisation option");
    end if;

    annotation (
      Icon(graphics={Text(extent={{-100,-90},{100,-116}},
                                                       textString="%name")}),
      Documentation(info="<html>
<p>This model describes a simple free-surface cylindrical water tank. The model is based on mass and energy balances, assuming that no heat transfer takes place except through the inlet and outlet flows. </p>
<p>The pressure at the inlet and outlet ports is the ambient pressure plus the static head due to the level, while the pressure at the inletTop port is the ambient pressure.</p>
</html>", revisions="<html>
<ul>
<li><i>29 Jul 2017</i> by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>Added inletTop port.</li>
<li><i>30 May 2005</i> by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>Initialisation support added.</li>
<li><i>16 Dec 2004</i> by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>Standard medium definition added.</li>
<li><i>22 Jun 2004</i> by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>Improved equations and adapted to Modelica.Media. </li>
<li><i>1 Oct 2003</i> by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>First release.</li>
</ul>
</html>"),
      Diagram(graphics));
  end Tank;

  model Flow1DFV
    "1-dimensional fluid flow model for water/steam (finite volumes)"
    extends BaseClasses.Flow1DBase;
    import ThermoPower.Choices.Flow1D.FFtypes;
    import ThermoPower.Choices.Flow1D.HCtypes;

    parameter SI.PerUnit wnm = 1e-3 "Maximum fraction of the nominal flow rate allowed as reverse flow";
    parameter Boolean fixedMassFlowSimplified = false "Fix flow rate = wnom for simplified homotopy model"
        annotation (Dialog(tab="Initialisation"));

    Medium.ThermodynamicState fluidState[N]
      "Thermodynamic state of the fluid at the nodes";
    SI.Length omega_hyd "Wet perimeter (single tube)";
    SI.Pressure Dpfric "Pressure drop due to friction (total)";
    SI.Pressure Dpfric1
      "Pressure drop due to friction (from inlet to capacitance)";
    SI.Pressure Dpfric2
      "Pressure drop due to friction (from capacitance to outlet)";
    SI.Pressure Dpstat "Pressure drop due to static head";
    Medium.MassFlowRate win "Flow rate at the inlet (single tube)";
    Medium.MassFlowRate wout "Flow rate at the outlet (single tube)";
    Real Kf "Hydraulic friction coefficient";
    Real dwdt "Dynamic momentum term";
    SI.PerUnit Cf "Fanning friction factor";
    Medium.AbsolutePressure p(start=pstart,stateSelect=StateSelect.prefer)
      "Fluid pressure for property calculations";
    Medium.MassFlowRate w(start=wnom/Nt) "Mass flow rate (single tube)";
    Medium.MassFlowRate wbar[N - 1](each start=wnom/Nt)
      "Average flow rate through volumes (single tube)";
    SI.Power Q_single[N-1] = heatTransfer.Qvol/Nt
      "Heat flows entering the volumes from the lateral boundary (single tube)";
  //   MassFlowRate wstar[N];
    SI.Velocity u[N] "Fluid velocity";
    Medium.Temperature T[N] "Fluid temperature";
    Medium.SpecificEnthalpy h[N](start=hstart)
      "Fluid specific enthalpy at the nodes";
    Medium.SpecificEnthalpy htilde[N - 1](start=hstart[2:N],each stateSelect=StateSelect.prefer)
      "Enthalpy state variables";
    Medium.Density rho[N] "Fluid nodal density";
    SI.Mass M "Fluid mass (single tube)";
    SI.Mass Mtot "Fluid mass (total)";
    SI.MassFlowRate dMdt[N - 1]
      "Time derivative of mass in each cell between two nodes";
    replaceable model HeatTransfer = Thermal.HeatTransferFV.IdealHeatTransfer
      constrainedby ThermoPower.Thermal.BaseClasses.DistributedHeatTransferFV
      annotation (choicesAllMatching=true);
    HeatTransfer heatTransfer(
      redeclare package Medium = Medium,
      final Nf=N,
      final Nw=Nw,
      final Nt=Nt,
      final L=L,
      final A=A,
      final Dhyd=Dhyd,
      final omega=omega,
      final wnom=wnom/Nt,
      final w=w*ones(N),
      final fluidState=fluidState) "Instantiated heat transfer model";

    ThermoPower.Thermal.DHTVolumes wall(final N=Nw)
      annotation (Placement(transformation(extent={{-40,40},{40,60}},
            rotation=0)));
  protected
    Medium.Density rhobar[N - 1] "Fluid average density";
    SI.SpecificVolume vbar[N - 1] "Fluid average specific volume";
    //HeatFlux phibar[N - 1] "Average heat flux";
    SI.DerDensityByEnthalpy drdh[N] "Derivative of density by enthalpy";
    SI.DerDensityByEnthalpy drbdh[N - 1]
      "Derivative of average density by enthalpy";
    SI.DerDensityByPressure drdp[N] "Derivative of density by pressure";
    SI.DerDensityByPressure drbdp[N - 1]
      "Derivative of average density by pressure";
  equation
    //All equations are referred to a single tube
    // Friction factor selection
    omega_hyd = 4*A/Dhyd;
    if FFtype == FFtypes.Kfnom then
      Kf = Kfnom*Kfc;
    elseif FFtype == FFtypes.OpPoint then
      Kf = dpnom*rhonom/(wnom/Nt)^2*Kfc;
    elseif FFtype == FFtypes.Cfnom then
      Cf = Cfnom*Kfc;
    elseif FFtype == FFtypes.Colebrook then
      Cf = f_colebrook(
          w,
          Dhyd/A,
          e,
          Medium.dynamicViscosity(fluidState[integer(N/2)]))*Kfc;
    else  // if FFtype == FFtypes.NoFriction then
      Cf = 0;
    end if;
    Kf = Cf*omega_hyd*L/(2*A^3)
      "Relationship between friction coefficient and Fanning friction factor";
    assert(Kf >= 0, "Negative friction coefficient");

    // Dynamic momentum term
    if DynamicMomentum then
      dwdt = der(w);
    else
      dwdt = 0;
    end if;

    sum(dMdt) = (infl.m_flow + outfl.m_flow)/Nt "Mass balance";
    L/A*dwdt + (outfl.p - infl.p) + Dpstat + Dpfric = 0 "Momentum balance";
    Dpfric = Dpfric1 + Dpfric2 "Total pressure drop due to friction";
    if FFtype == FFtypes.NoFriction then
      Dpfric1 = 0;
      Dpfric2 = 0;
    elseif HydraulicCapacitance == HCtypes.Middle then
      //assert((N-1)-integer((N-1)/2)*2 == 0, "N must be odd");
      Dpfric1 = homotopy(Kf*squareReg(win, wnom/Nt*wnf)*sum(vbar[1:integer((N
         - 1)/2)])/(N - 1), dpnom/2/(wnom/Nt)*win)
        "Pressure drop from inlet to capacitance";
      Dpfric2 = homotopy(Kf*squareReg(wout, wnom/Nt*wnf)*sum(vbar[1 + integer((
        N - 1)/2):N - 1])/(N - 1), dpnom/2/(wnom/Nt)*wout)
        "Pressure drop from capacitance to outlet";
    elseif HydraulicCapacitance == HCtypes.Upstream then
      Dpfric1 = 0 "Pressure drop from inlet to capacitance";
      Dpfric2 = homotopy(Kf*squareReg(wout, wnom/Nt*wnf)*sum(vbar)/(N - 1),
                         dpnom/(wnom/Nt)*wout)
        "Pressure drop from capacitance to outlet";
    else // if HydraulicCapacitance == HCtypes.Downstream then
      Dpfric1 = homotopy(Kf*squareReg(win, wnom/Nt*wnf)*sum(vbar)/(N - 1),
                         dpnom/(wnom/Nt)*win)
        "Pressure drop from inlet to capacitance";
      Dpfric2 = 0 "Pressure drop from capacitance to outlet";
    end if "Pressure drop due to friction";
    Dpstat = if abs(dzdx) < 1e-6 then 0 else g*l*dzdx*sum(rhobar)
      "Pressure drop due to static head";
    for j in 1:N-1 loop
      if Medium.singleState then
        A*l*rhobar[j]*der(htilde[j]) + wbar[j]*(h[j + 1] - h[j]) = Q_single[j]
          "Energy balance (pressure effects neglected)";
          //Qvol = l*omega*phibar[j]
      else
        A*l*rhobar[j]*der(htilde[j]) + wbar[j]*(h[j + 1] - h[j]) - A*l*der(p) =
          Q_single[j] "Energy balance";  //Qvol = l*omega*phibar[j]
      end if;
      dMdt[j] = A*l*(drbdh[j]*der(htilde[j]) + drbdp[j]*der(p))
        "Mass derivative for each volume";
      // Average volume quantities
      rhobar[j] = (rho[j] + rho[j + 1])/2;
      drbdp[j] = (drdp[j] + drdp[j + 1])/2;
      drbdh[j] = (drdh[j] + drdh[j + 1])/2;
      vbar[j] = 1/rhobar[j];
      if fixedMassFlowSimplified then
        wbar[j] = homotopy(infl.m_flow/Nt - sum(dMdt[1:j - 1]) - dMdt[j]/2, wnom/Nt);
      else
        wbar[j] = infl.m_flow/Nt - sum(dMdt[1:j - 1]) - dMdt[j]/2;
      end if;
    end for;

    // for j in 1:N loop
    //   wstar[j] = homotopy(infl.m_flow/Nt - sum(dMdt[1:j - 1]) - dMdt[j]/2, wnom/Nt);
    // end for;

    // Fluid property calculations
    for j in 1:N loop
      fluidState[j] = Medium.setState_phX(p, h[j]);
      T[j] = Medium.temperature(fluidState[j]);
      rho[j] = Medium.density(fluidState[j]);
      drdp[j] = if Medium.singleState then 0 else Medium.density_derp_h(
        fluidState[j]);
      drdh[j] = Medium.density_derh_p(fluidState[j]);
      u[j] = w/(rho[j]*A);
    end for;

    // Boundary conditions
    win = infl.m_flow/Nt;
    wout = -outfl.m_flow/Nt;
    assert(HydraulicCapacitance == HCtypes.Upstream or
             HydraulicCapacitance == HCtypes.Middle or
             HydraulicCapacitance == HCtypes.Downstream,
             "Unsupported HydraulicCapacitance option");
    if HydraulicCapacitance == HCtypes.Middle then
      p = infl.p - Dpfric1 - Dpstat/2;
      w = win;
    elseif HydraulicCapacitance == HCtypes.Upstream then
      p = infl.p;
      w = -outfl.m_flow/Nt;
    else  // if HydraulicCapacitance == HCtypes.Downstream then
      p = outfl.p;
      w = win;
    end if;
    infl.h_outflow = h[1];
    outfl.h_outflow = htilde[N - 1];

     h[1] = inStream(infl.h_outflow);
     h[2:N] = htilde;

    connect(wall,heatTransfer.wall);

    Q = heatTransfer.Q "Total heat flow through lateral boundary";
    M = sum(rhobar)*A*l "Fluid mass (single tube)";
    Mtot = M*Nt "Fluid mass (total)";
    Tr = noEvent(M/max(win, Modelica.Constants.eps)) "Residence time";

    assert(w > -wnom*wnm, "Reverse flow not allowed, maybe you connected the component with wrong orientation");
  initial equation
    if initOpt == Choices.Init.Options.noInit then
      // do nothing
    elseif initOpt == Choices.Init.Options.fixedState then
      if not noInitialPressure then
        p = pstart;
      end if;
      htilde = hstart[2:N];
    elseif initOpt == Choices.Init.Options.steadyState then
      der(htilde) = zeros(N - 1);
      if (not Medium.singleState) and not noInitialPressure then
        der(p) = 0;
      end if;
    elseif initOpt == Choices.Init.Options.steadyStateNoP then
      der(htilde) = zeros(N - 1);
      assert(false, "initOpt = steadyStateNoP deprecated, use steadyState and noInitialPressure",AssertionLevel.warning);
    elseif initOpt == Choices.Init.Options.steadyStateNoT and not Medium.singleState then
      der(p) = 0;
    else
      assert(false, "Unsupported initialisation option");
    end if;
    annotation (
      Diagram(graphics),
      Icon(graphics={Text(extent={{-100,-60},{100,-100}},textString="%name")}),
      Documentation(info="<HTML>
<p>This model describes the flow of water or steam in a rigid tube. The basic modelling assumptions are:
<ul><li>The fluid state is always one-phase (i.e. subcooled liquid or superheated steam).
<li>Uniform velocity is assumed on the cross section, leading to a 1-D distributed parameter model.
<li>Turbulent friction is always assumed; a small linear term is added to avoid numerical singularities at zero flowrate. The friction effects are not accurately computed in the laminar and transitional flow regimes, which however should not be an issue in most applications using water or steam as a working fluid.
<li>The model is based on dynamic mass, momentum, and energy balances. The dynamic momentum term can be switched off, to avoid the fast oscillations that can arise from its coupling with the mass balance (sound wave dynamics).
<li>The longitudinal heat diffusion term is neglected.
<li>The energy balance equation is written by assuming a uniform pressure distribution; the compressibility effects are lumped at the inlet, at the outlet, or at the middle of the pipe.
<li>The fluid flow can exchange thermal power through the lateral tube boundary, by means of the <tt>wall</tt> connector, that actually represents the wall surface with its temperature. The heat flow is computed by an instance of the replaceable HeatTransfer model; various heat transfer models are available in the ThermoPower.Thermal.HeatTransferFV package.
</ul>
<p>The mass, momentum and energy balance equation are discretised with the finite volume method. The state variables are one pressure, one flowrate (optional) and N-1 specific enthalpies.
<p>The turbulent friction factor can be either assumed as a constant, or computed by Colebrook's equation. In the former case, the friction factor can be supplied directly, or given implicitly by a specified operating point. In any case, the multiplicative correction coefficient <tt>Kfc</tt> can be used to modify the friction coefficient, e.g. to fit experimental data.
<p>A small linear pressure drop is added to avoid numerical singularities at low or zero flowrate. The <tt>wnom</tt> parameter must be always specified: the additional linear pressure drop is such that it is equal to the turbulent pressure drop when the flowrate is equal to <tt>wnf*wnom</tt> (the default value is 1% of the nominal flowrate). Increase <tt>wnf</tt> if numerical instabilities occur in tubes with very low pressure drops.
<p>Flow reversal is not supported by this model; if you need flow reversal, please consider using the Flow1DFEM model.
<p><b>Modelling options</b></p>
<p>Thermal variables (enthalpy, temperature, density) are computed in <tt>N</tt> equally spaced nodes, including the inlet (node 1) and the outlet (node N); <tt>N</tt> must be greater than or equal to 2.
<p>The following options are available to specify the friction coefficient:
<ul><li><tt>FFtype = FFtypes.Kfnom</tt>: the hydraulic friction coefficient <tt>Kf</tt> is set directly to <tt>Kfnom</tt>.
<li><tt>FFtype = FFtypes.OpPoint</tt>: the hydraulic friction coefficient is specified by a nominal operating point (<tt>wnom</tt>,<tt>dpnom</tt>, <tt>rhonom</tt>).
<li><tt>FFtype = FFtypes.Cfnom</tt>: the friction coefficient is computed by giving the (constant) value of the Fanning friction factor <tt>Cfnom</tt>.
<li><tt>FFtype = FFtypes.Colebrook</tt>: the Fanning friction factor is computed by Colebrook's equation (assuming Re > 2100, e.g. turbulent flow).
<li><tt>FFtype = FFtypes.NoFriction</tt>: no friction is assumed across the pipe.</ul>
<p>The dynamic momentum term is included or neglected depending on the <tt>DynamicMomentum</tt> parameter.
<p>If <tt>HydraulicCapacitance = HCtypes.Downstream</tt> (default option) then the compressibility effect depending on the pressure derivative is lumped at the outlet, while the optional dynamic momentum term depending on the flowrate is lumped at the inlet; therefore, the state variables are the outlet pressure and the inlet flowrate. If <tt>HydraulicCapacitance = HCtypes.Upstream</tt> the reverse takes place.
 If <tt>HydraulicCapacitance = HCtypes.Middle</tt>, the compressibility effect is lumped at the middle of the pipe; to use this option, an odd number of nodes N is required.
<p>Start values for the pressure and flowrate state variables are specified by <tt>pstart</tt>, <tt>wstart</tt>. The start values for the node enthalpies are linearly distributed from <tt>hstartin</tt> at the inlet to <tt>hstartout</tt> at the outlet.
<p>A bank of <tt>Nt</tt> identical tubes working in parallel can be modelled by setting <tt>Nt > 1</tt>. The geometric parameters always refer to a <i>single</i> tube.
<p>This models makes the temperature and external heat flow distributions available to connected components through the <tt>wall</tt> connector. If other variables (e.g. the heat transfer coefficient) are needed by external components to compute the actual heat flow, the <tt>wall</tt> connector can be replaced by an extended version of the <tt>DHT</tt> connector.
</HTML>", revisions="<html>
<ul>
<li><i>16 Sep 2005</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Option to lump compressibility at the middle added.</li>
<li><i>30 May 2005</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Initialisation support added.</li>
<li><i>24 Mar 2005</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       <tt>FFtypes</tt> package and <tt>NoFriction</tt> option added.</li>
<li><i>16 Dec 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Standard medium definition added.</li>
<li><i>8 Oct 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Model now based on <tt>Flow1DBase</tt>.
<li><i>24 Sep 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Removed <tt>wstart</tt>, <tt>pstart</tt>. Added <tt>pstartin</tt>, <tt>pstartout</tt>.
<li><i>22 Jun 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Adapted to Modelica.Media.
<li><i>15 Jan 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Computation of fluid velocity <i>u</i> added. Improved treatment of geometric parameters</li>.
<li><i>1 Oct 2003</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       First release.</li>
</ul>
</html>
"));
  end Flow1DFV;

  model Flow1DFV2w "Same as Flow1DFV with two walls and heat transfer models"
    extends Flow1DFV(
      Q_single = heatTransfer.Qvol/Nt + heatTransfer2.Qvol/Nt);
    replaceable model HeatTransfer2 = Thermal.HeatTransferFV.IdealHeatTransfer
      constrainedby ThermoPower.Thermal.BaseClasses.DistributedHeatTransferFV
      annotation (choicesAllMatching=true);
    HeatTransfer heatTransfer2(
      redeclare package Medium = Medium,
      final Nf=N,
      final Nw=Nw,
      final Nt=Nt,
      final L=L,
      final A=A,
      final Dhyd=Dhyd,
      final omega=omega,
      final wnom=wnom/Nt,
      final w=w*ones(N),
      final fluidState=fluidState) "Instantiated heat transfer model";

    Thermal.DHTVolumes wall2(final N=Nw)
      annotation (Placement(transformation(extent={{-60,-60},{60,-40}},
                                                                      rotation=0)));
  equation
    connect(wall2,heatTransfer2.wall);
    annotation (Diagram(coordinateSystem(preserveAspectRatio=false, extent={{-100,
              -100},{100,100}}), graphics), Icon(coordinateSystem(
            preserveAspectRatio=false, extent={{-100,-100},{100,100}})));
  end Flow1DFV2w;

  model Flow1DFV2ph
    "1-dimensional fluid flow model for water/steam (finite volumes, 2-phase)"
    extends BaseClasses.Flow1DBase(redeclare replaceable package Medium =
          StandardWater "Medium model" constrainedby
        Modelica.Media.Interfaces.PartialTwoPhaseMedium,
        FluidPhaseStart=Choices.FluidPhase.FluidPhases.TwoPhases);
    replaceable model HeatTransfer = Thermal.HeatTransferFV.IdealHeatTransfer
      constrainedby ThermoPower.Thermal.BaseClasses.DistributedHeatTransferFV
      annotation (choicesAllMatching=true);
    HeatTransfer heatTransfer(
      redeclare package Medium = Medium,
      final Nf=N,
      final Nw=Nw,
      final Nt=Nt,
      final L=L,
      final A=A,
      final Dhyd=Dhyd,
      final omega=omega,
      final wnom=wnom/Nt,
      final w=w*ones(N),
      final fluidState=fluidState) "Instantiated heat transfer model";

    ThermoPower.Thermal.DHTVolumes wall(final N=Nw) annotation (Dialog(enable=
            false), Placement(transformation(extent={{-40,40},{40,60}},
            rotation=0)));
    import ThermoPower.Choices.Flow1D.FFtypes;
    import ThermoPower.Choices.Flow1D.HCtypes;
    // package SmoothMedium = Medium (final smoothModel=true);
    constant SI.Pressure pzero=10 "Small deltap for calculations";
    constant Medium.AbsolutePressure pc=Medium.fluidConstants[1].criticalPressure;
    constant SI.SpecificEnthalpy hzero=1e-3 "Small value for deltah";

    parameter SI.PerUnit wnm = 1e-3 "Maximum fraction of the nominal flow rate allowed as reverse flow";
    parameter Boolean fixedMassFlowSimplified = false "Fix flow rate = wnom for simplified homotopy model";

    // SmoothMedium.ThermodynamicState fluidState[N]
    //   "Thermodynamic state of the fluid at the nodes";
    Medium.ThermodynamicState fluidState[N]
      "Thermodynamic state of the fluid at the nodes";
    Medium.SaturationProperties sat "Properties of saturated fluid";
    SI.Length omega_hyd "Wet perimeter (single tube)";
    SI.Pressure Dpfric "Pressure drop due to friction";
    SI.Pressure Dpstat "Pressure drop due to static head";
    Real Kf[N - 1] "Friction coefficient";
    Real Kfl[N - 1] "Linear friction coefficient";
    Real Cf[N - 1] "Fanning friction factor";
    Real dwdt "Dynamic momentum term";
    Medium.AbsolutePressure p(start=pstart)
      "Fluid pressure for property calculations";

                                          /*, stateSelect=StateSelect.prefer*/
    SI.Pressure dpf[N - 1] "Pressure drop due to friction between two nodes";
    Medium.MassFlowRate w(start=wnom/Nt) "Mass flowrate (single tube)";
    Medium.MassFlowRate wbar[N - 1](each start=wnom/Nt)
      "Average mass flow rates (single tube)";
    SI.Power Q_single[N-1] = heatTransfer.Qvol/Nt
      "Heat flows entering the volumes from the lateral boundary (single tube)";
    SI.Velocity u[N] "Fluid velocity";
    Medium.Temperature T[N] "Fluid temperature";
    Medium.Temperature Ts "Saturated water temperature";
    Medium.SpecificEnthalpy h[N](start=hstart) "Fluid specific enthalpy";
    Medium.SpecificEnthalpy htilde[N - 1](start=hstart[2:N])
      "Enthalpy state variables";                          /*,each stateSelect=StateSelect.prefer*/
    Medium.SpecificEnthalpy hl "Saturated liquid temperature";
    Medium.SpecificEnthalpy hv "Saturated vapour temperature";
    SI.PerUnit x[N] "Steam quality";
    Medium.Density rho[N] "Fluid density";
    Units.LiquidDensity rhol "Saturated liquid density";
    Units.GasDensity rhov "Saturated vapour density";
    SI.Mass M "Fluid mass";
    SI.Mass Mtot "Fluid mass (total)";
  protected
    SI.DerEnthalpyByPressure dhldp
      "Derivative of saturated liquid enthalpy by pressure";
    SI.DerEnthalpyByPressure dhvdp
      "Derivative of saturated vapour enthalpy by pressure";
    Medium.Density rhobar[N - 1] "Fluid average density";
    SI.DerDensityByPressure drdp[N] "Derivative of density by pressure";
    SI.DerDensityByPressure drbdp[N - 1]
      "Derivative of average density by pressure";
    SI.DerDensityByPressure drldp
      "Derivative of saturated liquid density by pressure";
    SI.DerDensityByPressure drvdp
      "Derivative of saturated vapour density by pressure";
    SI.SpecificVolume vbar[N - 1] "Average specific volume";
    SI.DerDensityByEnthalpy drdh[N] "Derivative of density by enthalpy";
    SI.DerDensityByEnthalpy drbdh1[N - 1]
      "Derivative of average density by left enthalpy";
    SI.DerDensityByEnthalpy drbdh2[N - 1]
      "Derivative of average density by right enthalpy";
    Real AA;
    Real AA1;
    SI.MassFlowRate dMdt[N - 1] "Derivative of fluid mass in each volume";
  equation
    //All equations are referred to a single tube
    omega_hyd = 4*A/Dhyd;
    // Friction factor selection
    for j in 1:(N - 1) loop
      if FFtype == FFtypes.Kfnom then
        Kf[j] = Kfnom*Kfc/(N - 1);
        Cf[j] = 2*Kf[j]*A^3/(omega_hyd*l);
      elseif FFtype == FFtypes.OpPoint then
        Kf[j] = dpnom*rhonom/(wnom/Nt)^2/(N - 1)*Kfc;
        Cf[j] = 2*Kf[j]*A^3/(omega_hyd*l);
      elseif FFtype == FFtypes.Cfnom then
        Kf[j] = Cfnom*omega_hyd*l/(2*A^3)*Kfc;
        Cf[j] = 2*Kf[j]*A^3/(omega_hyd*l);
      elseif FFtype == FFtypes.Colebrook then
        Cf[j] = if noEvent(htilde[j] < hl or htilde[j] > hv) then f_colebrook(
            w,
            Dhyd/A,
            e,
            Medium.dynamicViscosity(fluidState[j]))*Kfc else f_colebrook_2ph(
            w,
            Dhyd/A,
            e,
            Medium.dynamicViscosity(Medium.setBubbleState(sat, 1)),
            Medium.dynamicViscosity(Medium.setDewState(sat, 1)),
            x[j])*Kfc;
        Kf[j] = Cf[j]*omega_hyd*l/(2*A^3);
      elseif FFtype == FFtypes.NoFriction then
        Cf[j] = 0;
        Kf[j] = 0;
      else
        assert(FFtype <> FFtypes.NoFriction, "Unsupported FFtype");
        Cf[j] = 0;
        Kf[j] = 0;
      end if;
      assert(Kf[j] >= 0, "Negative friction coefficient");
      Kfl[j] = wnom/Nt*wnf*Kf[j];
    end for;

    // Dynamic momentum term
    if DynamicMomentum then
      dwdt = der(w);
    else
      dwdt = 0;
    end if;

    sum(dMdt) = (infl.m_flow/Nt + outfl.m_flow/Nt) "Mass balance";
    sum(dpf) = Dpfric "Total pressure drop due to friction";
    Dpstat = if abs(dzdx) < 1e-6 then 0 else g*l*dzdx*sum(rhobar)
      "Pressure drop due to static head";
    L/A*dwdt + (outfl.p - infl.p) + Dpstat + Dpfric = 0 "Momentum balance";
    for j in 1:(N - 1) loop
      A*l*rhobar[j]*der(htilde[j]) + wbar[j]*(h[j + 1] - h[j]) - A*l*der(p) = Q_single[j]
        "Energy balance";
      dMdt[j] = A*l*(drbdh1[j]*der(h[j]) + drbdh2[j]*der(h[j + 1]) + drbdp[j]*
        der(p)) "Mass balance for each volume";
      // Average volume quantities
      vbar[j] = 1/rhobar[j] "Average specific volume";
      if fixedMassFlowSimplified then
        wbar[j] = homotopy(infl.m_flow/Nt - sum(dMdt[1:j - 1]) - dMdt[j]/2, wnom/Nt);
      else
        wbar[j] = infl.m_flow/Nt - sum(dMdt[1:j - 1]) - dMdt[j]/2;
      end if;
      dpf[j] = (if FFtype == FFtypes.NoFriction then 0 else homotopy(smooth(1,
        Kf[j]*squareReg(w, wnom/Nt*wnf))*vbar[j], dpnom/(N - 1)/(wnom/Nt)*w));
      if avoidInletEnthalpyDerivative and j == 1 then
        // first volume properties computed by the outlet properties
        rhobar[j] = rho[j + 1];
        drbdp[j] = drdp[j + 1];
        drbdh1[j] = 0;
        drbdh2[j] = drdh[j + 1];
      elseif noEvent((h[j] < hl and h[j + 1] < hl) or (h[j] > hv and h[j + 1]
           > hv) or p >= (pc - pzero) or abs(h[j + 1] - h[j]) < hzero) then
        // 1-phase or almost uniform properties
        rhobar[j] = (rho[j] + rho[j + 1])/2;
        drbdp[j] = (drdp[j] + drdp[j + 1])/2;
        drbdh1[j] = drdh[j]/2;
        drbdh2[j] = drdh[j + 1]/2;
      elseif noEvent(h[j] >= hl and h[j] <= hv and h[j + 1] >= hl and h[j + 1]
           <= hv) then
        // 2-phase
        rhobar[j] = AA*log(rho[j]/rho[j + 1])/(h[j + 1] - h[j]);
        drbdp[j] = (AA1*log(rho[j]/rho[j + 1]) + AA*(1/rho[j]*drdp[j] - 1/rho[j
           + 1]*drdp[j + 1]))/(h[j + 1] - h[j]);
        drbdh1[j] = (rhobar[j] - rho[j])/(h[j + 1] - h[j]);
        drbdh2[j] = (rho[j + 1] - rhobar[j])/(h[j + 1] - h[j]);
      elseif noEvent(h[j] < hl and h[j + 1] >= hl and h[j + 1] <= hv) then
        // liquid/2-phase
        rhobar[j] = ((rho[j] + rhol)*(hl - h[j])/2 + AA*log(rhol/rho[j + 1]))/(
          h[j + 1] - h[j]);
        drbdp[j] = ((drdp[j] + drldp)*(hl - h[j])/2 + (rho[j] + rhol)/2*dhldp
           + AA1*log(rhol/rho[j + 1]) + AA*(1/rhol*drldp - 1/rho[j + 1]*drdp[j
           + 1]))/(h[j + 1] - h[j]);
        drbdh1[j] = (rhobar[j] - (rho[j] + rhol)/2 + drdh[j]*(hl - h[j])/2)/(h[
          j + 1] - h[j]);
        drbdh2[j] = (rho[j + 1] - rhobar[j])/(h[j + 1] - h[j]);
      elseif noEvent(h[j] >= hl and h[j] <= hv and h[j + 1] > hv) then
        // 2-phase/vapour
        rhobar[j] = (AA*log(rho[j]/rhov) + (rhov + rho[j + 1])*(h[j + 1] - hv)/
          2)/(h[j + 1] - h[j]);
        drbdp[j] = (AA1*log(rho[j]/rhov) + AA*(1/rho[j]*drdp[j] - 1/rhov*drvdp)
           + (drvdp + drdp[j + 1])*(h[j + 1] - hv)/2 - (rhov + rho[j + 1])/2*
          dhvdp)/(h[j + 1] - h[j]);
        drbdh1[j] = (rhobar[j] - rho[j])/(h[j + 1] - h[j]);
        drbdh2[j] = ((rhov + rho[j + 1])/2 - rhobar[j] + drdh[j + 1]*(h[j + 1]
           - hv)/2)/(h[j + 1] - h[j]);
      elseif noEvent(h[j] < hl and h[j + 1] > hv) then
        // liquid/2-phase/vapour
        rhobar[j] = ((rho[j] + rhol)*(hl - h[j])/2 + AA*log(rhol/rhov) + (rhov
           + rho[j + 1])*(h[j + 1] - hv)/2)/(h[j + 1] - h[j]);
        drbdp[j] = ((drdp[j] + drldp)*(hl - h[j])/2 + (rho[j] + rhol)/2*dhldp
           + AA1*log(rhol/rhov) + AA*(1/rhol*drldp - 1/rhov*drvdp) + (drvdp +
          drdp[j + 1])*(h[j + 1] - hv)/2 - (rhov + rho[j + 1])/2*dhvdp)/(h[j +
          1] - h[j]);
        drbdh1[j] = (rhobar[j] - (rho[j] + rhol)/2 + drdh[j]*(hl - h[j])/2)/(h[
          j + 1] - h[j]);
        drbdh2[j] = ((rhov + rho[j + 1])/2 - rhobar[j] + drdh[j + 1]*(h[j + 1]
           - hv)/2)/(h[j + 1] - h[j]);
      elseif noEvent(h[j] >= hl and h[j] <= hv and h[j + 1] < hl) then
        // 2-phase/liquid
        rhobar[j] = (AA*log(rho[j]/rhol) + (rhol + rho[j + 1])*(h[j + 1] - hl)/
          2)/(h[j + 1] - h[j]);
        drbdp[j] = (AA1*log(rho[j]/rhol) + AA*(1/rho[j]*drdp[j] - 1/rhol*drldp)
           + (drldp + drdp[j + 1])*(h[j + 1] - hl)/2 - (rhol + rho[j + 1])/2*
          dhldp)/(h[j + 1] - h[j]);
        drbdh1[j] = (rhobar[j] - rho[j])/(h[j + 1] - h[j]);
        drbdh2[j] = ((rhol + rho[j + 1])/2 - rhobar[j] + drdh[j + 1]*(h[j + 1]
           - hl)/2)/(h[j + 1] - h[j]);
      elseif noEvent(h[j] > hv and h[j + 1] < hl) then
        // vapour/2-phase/liquid
        rhobar[j] = ((rho[j] + rhov)*(hv - h[j])/2 + AA*log(rhov/rhol) + (rhol
           + rho[j + 1])*(h[j + 1] - hl)/2)/(h[j + 1] - h[j]);
        drbdp[j] = ((drdp[j] + drvdp)*(hv - h[j])/2 + (rho[j] + rhov)/2*dhvdp
           + AA1*log(rhov/rhol) + AA*(1/rhov*drvdp - 1/rhol*drldp) + (drldp +
          drdp[j + 1])*(h[j + 1] - hl)/2 - (rhol + rho[j + 1])/2*dhldp)/(h[j +
          1] - h[j]);
        drbdh1[j] = (rhobar[j] - (rho[j] + rhov)/2 + drdh[j]*(hv - h[j])/2)/(h[
          j + 1] - h[j]);
        drbdh2[j] = ((rhol + rho[j + 1])/2 - rhobar[j] + drdh[j + 1]*(h[j + 1]
           - hl)/2)/(h[j + 1] - h[j]);
      else
        // vapour/2-phase
        rhobar[j] = ((rho[j] + rhov)*(hv - h[j])/2 + AA*log(rhov/rho[j + 1]))/(
          h[j + 1] - h[j]);
        drbdp[j] = ((drdp[j] + drvdp)*(hv - h[j])/2 + (rho[j] + rhov)/2*dhvdp
           + AA1*log(rhov/rho[j + 1]) + AA*(1/rhov*drvdp - 1/rho[j + 1]*drdp[j
           + 1]))/(h[j + 1] - h[j]);
        drbdh1[j] = (rhobar[j] - (rho[j] + rhov)/2 + drdh[j]*(hv - h[j])/2)/(h[
          j + 1] - h[j]);
        drbdh2[j] = (rho[j + 1] - rhobar[j])/(h[j + 1] - h[j]);
      end if;
    end for;

    // Saturated fluid property calculations
    sat = Medium.setSat_p(p);
    Ts = sat.Tsat;
    rhol = Medium.bubbleDensity(sat);
    rhov = Medium.dewDensity(sat);
    hl = Medium.bubbleEnthalpy(sat);
    hv = Medium.dewEnthalpy(sat);
    drldp = Medium.dBubbleDensity_dPressure(sat);
    drvdp = Medium.dDewDensity_dPressure(sat);
    dhldp = Medium.dBubbleEnthalpy_dPressure(sat);
    dhvdp = Medium.dDewEnthalpy_dPressure(sat);
    AA = (hv - hl)/(1/rhov - 1/rhol);
    AA1 = ((dhvdp - dhldp)*(rhol - rhov)*rhol*rhov - (hv - hl)*(rhov^2*drldp -
      rhol^2*drvdp))/(rhol - rhov)^2;

    // Fluid property calculations
    for j in 1:N loop
      fluidState[j] = Medium.setState_phX(p, h[j]);
      T[j] = Medium.temperature(fluidState[j]);
      rho[j] = Medium.density(fluidState[j]);
      drdp[j] = Medium.density_derp_h(fluidState[j]);
      drdh[j] = Medium.density_derh_p(fluidState[j]);
      u[j] = w/(rho[j]*A);
      x[j] = noEvent(if h[j] <= hl then 0 else if h[j] >= hv then 1 else (h[j]
         - hl)/(hv - hl));
    end for;

    // Selection of representative pressure and flow rate variables
    if HydraulicCapacitance == HCtypes.Upstream then
      p = infl.p;
      w = -outfl.m_flow/Nt;
    else
      p = outfl.p;
      w = infl.m_flow/Nt;
    end if;

    // Boundary conditions
    infl.h_outflow = htilde[1];
    outfl.h_outflow = htilde[N - 1];
    h[1] = inStream(infl.h_outflow);
    h[2:N] = htilde;

    connect(wall,heatTransfer.wall);

    Q = heatTransfer.Q "Total heat flow through lateral boundary";
    M = sum(rhobar)*A*l "Fluid mass (single tube)";
    Mtot = M*Nt "Fluid mass (total)";
    Tr = noEvent(M/max(infl.m_flow/Nt, Modelica.Constants.eps))
      "Residence time";

    assert(infl.m_flow > -wnom*wnm, "Reverse flow not allowed, maybe you connected the component with wrong orientation");
  initial equation
    if initOpt == Choices.Init.Options.noInit then
      // do nothing
    elseif initOpt == Choices.Init.Options.fixedState then
      if not noInitialPressure then
        p = pstart;
      end if;
      htilde = hstart[2:N];
    elseif initOpt == Choices.Init.Options.steadyState then
      der(htilde) = zeros(N - 1);
      if (not Medium.singleState) and not noInitialPressure then
        der(p) = 0;
      end if;
    elseif initOpt == Choices.Init.Options.steadyStateNoP then
      der(htilde) = zeros(N - 1);
      assert(false, "initOpt = steadyStateNoP deprecated, use steadyState and noInitialPressure",AssertionLevel.warning);
    elseif initOpt == Choices.Init.Options.steadyStateNoT and not Medium.singleState then
      der(p) = 0;
    else
      assert(false, "Unsupported initialisation option");
    end if;

    annotation (
      Diagram(graphics),
      Icon(graphics={Text(extent={{-100,-60},{100,-100}},textString="%name")}),
      Documentation(info="<HTML>
<p>This model describes the flow of water or steam in a rigid tube. The basic modelling assumptions are:
<ul><li>The fluid state is either one-phase, or a two-phase mixture.
<li>In case of two-phase flow, the same velocity is assumed for both phases (homogeneous model).
<li>Uniform velocity is assumed on the cross section, leading to a 1-D distributed parameter model.
<li>Turbulent friction is always assumed; a small linear term is added to avoid numerical singularities at zero flowrate. The friction effects are not accurately computed in the laminar and transitional flow regimes, which however should not be an issue in most applications using water or steam as a working fluid.
<li>The model is based on dynamic mass, momentum, and energy balances. The dynamic momentum term can be switched off, to avoid the fast oscillations that can arise from its coupling with the mass balance (sound wave dynamics).
<li>The longitudinal heat diffusion term is neglected.
<li>The energy balance equation is written by assuming a uniform pressure distribution; the pressure drop is lumped either at the inlet or at the outlet.
<li>The fluid flow can exchange thermal power through the lateral surface, which is represented by the <tt>wall</tt> connector. The actual heat flux must be computed by a connected component (heat transfer computation module).
</ul>
<p>The mass, momentum, and energy balance equation are discretised with the finite volume method. The state variables are one pressure, one flowrate (optional) and N-1 specific enthalpies.
<p>The turbulent friction factor can be either assumed as a constant, or computed by Colebrook's equation. In the former case, the friction factor can be supplied directly, or given implicitly by a specified operating point. In any case, the multiplicative correction coefficient <tt>Kfc</tt> can be used to modify the friction coefficient, e.g. to fit experimental data.
<p>A small linear pressure drop is added to avoid numerical singularities at low or zero flowrate. The <tt>wnom</tt> parameter must be always specified: the additional linear pressure drop is such that it is equal to the turbulent pressure drop when the flowrate is equal to <tt>wnf*wnom</tt> (the default value is 1% of the nominal flowrate). Increase <tt>wnf</tt> if numerical instabilities occur in tubes with very low pressure drops.
<p>The model assumes that the mass flow rate is always from the inlet to the outlet. Small reverse flow is allowed (e.g. when closing a valve at the outlet), but the model will not account for it explicitly.
<p><b>Modelling options</b></p>
<p>Thermal variables (enthalpy, temperature, density) are computed in <tt>N</tt> equally spaced nodes, including the inlet (node 1) and the outlet (node N); <tt>N</tt> must be greater than or equal to 2.
<p>The dynamic momentum term is included or neglected depending on the <tt>DynamicMomentum</tt> parameter.
<p>The density is computed assuming a linear distribution of the specific
enthalpy between the nodes; this requires the availability of the time derivative of the inlet enthalpy. If this is not available, it is possible to set <tt>avoidInletEnthalpyDerivative</tt> to true, which will cause the mean density of the first volume to be approximated as its outlet density, thus avoiding the need of the inlet enthalpy derivative.
<p>The following options are available to specify the friction coefficient:
<ul><li><tt>FFtype = FFtypes.Kfnom</tt>: the hydraulic friction coefficient <tt>Kf</tt> is set directly to <tt>Kfnom</tt>.
<li><tt>FFtype = FFtypes.OpPoint</tt>: the hydraulic friction coefficient is specified by a nominal operating point (<tt>wnom</tt>,<tt>dpnom</tt>, <tt>rhonom</tt>).
<li><tt>FFtype = FFtypes.Cfnom</tt>: the friction coefficient is computed by giving the (constant) value of the Fanning friction factor <tt>Cfnom</tt>.
<li><tt>FFtype = FFtypes.Colebrook</tt>: the Fanning friction factor is computed by Colebrook's equation (assuming Re > 2100, e.g. turbulent flow).
<li><tt>FFtype = FFtypes.NoFriction</tt>: no friction is assumed across the pipe.</ul><p>If <tt>HydraulicCapacitance = 2</tt> (default option) then the mass storage term depending on the pressure is lumped at the outlet, while the optional momentum storage term depending on the flowrate is lumped at the inlet. If <tt>HydraulicCapacitance = 1</tt> the reverse takes place.
<p>Start values for pressure and flowrate are specified by <tt>pstart</tt>, <tt>wstart</tt>. The start values for the node enthalpies are linearly distributed from <tt>hstartin</tt> at the inlet to <tt>hstartout</tt> at the outlet.
<p>A bank of <tt>Nt</tt> identical tubes working in parallel can be modelled by setting <tt>Nt > 1</tt>. The geometric parameters always refer to a <i>single</i> tube.
<p>This models makes the temperature and external heat flow distributions visible through the <tt>wall</tt> connector. If other variables (e.g. the heat transfer coefficient) are needed by external components to compute the actual heat flow, the <tt>wall</tt> connector can be replaced by an extended version of the <tt>DHT</tt> connector.
</HTML>", revisions="<html>
<ul>
<li><i>27 Jul 2007</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Corrected error in the mass balance equation, which lead to loss/gain of
       mass during transients.</li>
<li><i>30 May 2005</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Initialisation support added.</li>
<li><i>24 Mar 2005</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       <tt>FFtypes</tt> package and <tt>NoFriction</tt> option added.</li>
<li><i>16 Dec 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Standard medium definition added.</li>
<li><i>8 Oct 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Model now based on <tt>Flow1DBase</tt>.
<li><i>24 Sep 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Removed <tt>wstart</tt>, <tt>pstart</tt>. Added <tt>pstartin</tt>, <tt>pstartout</tt>.
<li><i>28 Jul 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Adapted to <tt>Modelica.Media</tt>.
<li><i>15 Jan 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Computation of fluid velocity <i>u</i> added. Improved treatment of geometric parameters</li>
<li><i>1 Oct 2003</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       First release.</li>
</ul>
</html>"));
  end Flow1DFV2ph;

  model Flow1DFV2ph2w
    "Same as Flow1DFV with two walls and heat transfer models"
    extends Flow1DFV2ph(
      Q_single = heatTransfer.Qvol/Nt + heatTransfer2.Qvol/Nt);
    replaceable model HeatTransfer2 = Thermal.HeatTransferFV.IdealHeatTransfer
      constrainedby ThermoPower.Thermal.BaseClasses.DistributedHeatTransferFV
      annotation (choicesAllMatching=true);
    HeatTransfer heatTransfer2(
      redeclare package Medium = Medium,
      final Nf=N,
      final Nw=Nw,
      final Nt=Nt,
      final L=L,
      final A=A,
      final Dhyd=Dhyd,
      final omega=omega,
      final wnom=wnom/Nt,
      final w=w*ones(N),
      final fluidState=fluidState) "Instantiated heat transfer model";

    Thermal.DHTVolumes wall2(final N=Nw)
      annotation (Placement(transformation(extent={{-60,-60},{60,-40}},rotation=0)));
  equation
    connect(wall2,heatTransfer2.wall);
    annotation (Diagram(coordinateSystem(preserveAspectRatio=false, extent={{-100,
              -100},{100,100}}), graphics), Icon(coordinateSystem(
            preserveAspectRatio=false, extent={{-100,-100},{100,100}}), graphics));
  end Flow1DFV2ph2w;

  model Flow1DFEM
    "1-dimensional fluid flow model for water/steam (finite elements)"
    extends BaseClasses.Flow1DBase(Nw = N);
    replaceable model HeatTransfer = Thermal.HeatTransferFEM.IdealHeatTransfer
      constrainedby ThermoPower.Thermal.BaseClasses.DistributedHeatTransferFEM
      annotation (choicesAllMatching=true);
    HeatTransfer heatTransfer(
      redeclare package Medium = Medium,
      final Nf=N,
      final Nw=Nw,
      final Nt=Nt,
      final L=L,
      final A=A,
      final Dhyd=Dhyd,
      final omega=omega,
      final wnom=wnom/Nt,
      final w=w,
      final fluidState=fluidState) "Instantiated heat transfer model";
    ThermoPower.Thermal.DHTNodes wall(N=N) annotation (Dialog(enable=
            false), Placement(transformation(extent={{-40,40},{40,60}},
            rotation=0)));
    import ThermoPower.Choices.Flow1D.FFtypes;
    import ThermoPower.Choices.Flow1D.HCtypes;
    Medium.ThermodynamicState fluidState[N]
      "Thermodynamic state of the fluid at the nodes";
    parameter SI.PerUnit alpha(
      min=0,
      max=1) = 1 "Numerical stabilization coefficient";
    parameter SI.PerUnit ML(
      min=0,
      max=1) = 0 "Mass Lumping Coefficient";
    parameter SI.PerUnit wnf_bc=0.01
      "Fraction of the nominal total mass flow rate for boundary condition FEM regularization";
    parameter SI.PerUnit wnf_alpha = 0.01
      "Fraction of the nominal total mass flow rate for stabilization parameter regularization";
    parameter Boolean regularizeBoundaryConditions = false
      "Regularize boundary condition matrices";
    parameter Boolean idealGasDensityDistribution = false
      "Assume ideal-gas-type density distributions for mass balances";
    constant SI.Acceleration g=Modelica.Constants.g_n;
    final parameter Boolean evenN=(div(N, 2)*2 == N)
      "The number of nodes is even";
    SI.Length omega_hyd "Hydraulic perimeter (single tube)";
    Real Kf[N] "Friction coefficients";
    Real Cf[N] "Fanning friction factors";
    Real dwdt "Dynamic momentum term";
    Medium.AbsolutePressure p(start=pstart) "Fluid pressure";
    SI.Pressure Dpfric "Pressure drop due to friction (total)";
    SI.Pressure Dpfric1
      "Pressure drop due to friction (from inlet to capacitance)";
    SI.Pressure Dpfric2
      "Pressure drop due to friction (from capacitance to outlet)";
    SI.Pressure Dpstat "Pressure drop due to static head";
    Medium.MassFlowRate w[N](each start=wnom/Nt) "Mass flowrate (single tube)";
    SI.Velocity u[N] "Fluid velocity";
    SI.HeatFlux phi[N] "Heat flux entering the fluid";
    Medium.Temperature T[N] "Fluid temperature";
    Medium.SpecificEnthalpy h[N](start=hstart) "Fluid specific enthalpy";
    Medium.Density rho[N] "Fluid density";
    SI.SpecificVolume v[N] "Fluid specific volume";
    SI.Mass Mtot "Total mass of fluid";
  protected
    SI.DerDensityByEnthalpy drdh[N] "Derivative of density by enthalpy";
    SI.DerDensityByPressure drdp[N] "Derivative of density by pressure";
    Real dvdt[N] "Time derivatives of specific volume";

    Real Y[N, N];
    Real M[N, N];
    Real D[N];
    Real D1[N];
    Real D2[N];
    Real G[N];
    Real B[N, N];
    Real C[N, N];
    Real K[N, N];

    Real alpha_sgn[N];

    Real YY[N, N];

  equation
    //All equations are referred to a single tube

    // Selection of representative pressure variable
    if HydraulicCapacitance == HCtypes.Middle then
      p = infl.p - Dpfric1 - Dpstat/2;
    elseif HydraulicCapacitance == HCtypes.Upstream then
      p = infl.p;
    elseif HydraulicCapacitance == HCtypes.Downstream then
      p = outfl.p;
    else
      assert(false, "Unsupported HydraulicCapacitance option");
    end if;

    //Friction factor selection
    omega_hyd = 4*A/Dhyd;
    for i in 1:N loop
      if FFtype == FFtypes.Kfnom then
        Kf[i] = Kfnom*Kfc;
      elseif FFtype == FFtypes.OpPoint then
        Kf[i] = dpnom*rhonom/(wnom/Nt)^2*Kfc;
      elseif FFtype == FFtypes.Cfnom then
        Cf[i] = Cfnom*Kfc;
      elseif FFtype == FFtypes.Colebrook then
        Cf[i] = f_colebrook(
            w[i],
            Dhyd/A,
            e,
            Medium.dynamicViscosity(fluidState[i]))*Kfc;
      elseif FFtype == FFtypes.NoFriction then
        Cf[i] = 0;
      end if;
      assert(Kf[i] >= 0, "Negative friction coefficient");
      Kf[i] = Cf[i]*omega_hyd*L/(2*A^3)
        "Relationship between friction coefficient and Fanning friction factor";
    end for;

    //Dynamic Momentum [not] accounted for
    if DynamicMomentum then
      if HydraulicCapacitance == HCtypes.Upstream then
        dwdt = der(w[N]);
      elseif HydraulicCapacitance == HCtypes.Downstream then
        dwdt = der(w[1]);
      else
        assert(false,
          "DynamicMomentum == true requires either Upstream or Downstream capacitance");
      end if;
    else
      dwdt = 0;
    end if;

    L/A*dwdt + (outfl.p - infl.p) + Dpstat + Dpfric = 0
      "Momentum balance equation";

    w[1] = infl.m_flow/Nt "Inlet flow rate - single tube";
    w[N] = -outfl.m_flow/Nt "Outlet flow rate - single tube";

    Dpfric = Dpfric1 + Dpfric2 "Total pressure drop due to friction";

    if FFtype == FFtypes.NoFriction then
      Dpfric1 = 0;
      Dpfric2 = 0;
    else
      Dpfric1 = homotopy(sum(Kf[i]/L*squareReg(w[i], wnom/Nt*wnf)*D1[i]/rho[i]
        for i in 1:N), dpnom/2/(wnom/Nt)*w[1])
        "Pressure drop from inlet to capacitance";
      Dpfric2 = homotopy(sum(Kf[i]/L*squareReg(w[i], wnom/Nt*wnf)*D2[i]/rho[i]
        for i in 1:N), dpnom/2/(wnom/Nt)*w[N])
        "Pressure drop from capacitance to outlet";
    end if "Pressure drop due to friction";

    Dpstat = if abs(dzdx) < 1e-6 then 0 else g*dzdx*rho*D
      "Pressure drop due to static head";
    ((1 - ML)*Y + ML*YY)*der(h) + B/A*h + C*h/A = der(p)*G + M*(omega/A)*phi +
      K*w/A "Energy balance equation";

    // Fluid property calculations
    for j in 1:N loop
      fluidState[j] = Medium.setState_phX(p, h[j]);
      T[j] = Medium.temperature(fluidState[j]);
      rho[j] = Medium.density(fluidState[j]);
      drdp[j] = if Medium.singleState then 0 else Medium.density_derp_h(
        fluidState[j]);
      drdh[j] = Medium.density_derh_p(fluidState[j]);
      dvdt[j] = -1/rho[j]^2*(drdp[j]*der(p) + drdh[j]*der(h[j]));
      v[j] = 1/rho[j];
      u[j] = w[j]/(rho[j]*A);
    end for;

    //Boundary Values of outflowing fluid enthalpies
    h[1] = infl.h_outflow;
    h[N] = outfl.h_outflow;

    // Boundary values of heat flux
    phi = heatTransfer.phi_f;

    // Stabilization parameters depending of flow direction
    for i in 1:N loop
      alpha_sgn[i] = alpha*tanh(w[i]/(wnf_alpha*wnom/Nt));
    end for;

    for i in 1:N - 1 loop
      if idealGasDensityDistribution then
        (w[i + 1] - w[i]) = noEvent(
          if abs((v[i+1]-v[i])/v[i]) < 1e-7 then
             2*A*l/(v[i]+v[i+1])^2*(dvdt[i]+dvdt[i+1])
          else
             -A*l/(v[i+1]-v[i])*(
              (dvdt[i+1]*v[i]-dvdt[i]*v[i+1])/(v[i+1]*v[i]) -
              (dvdt[i+1]-dvdt[i])/(v[i+1]-v[i])*log(v[i+1]/v[i])))
          "Mass balance equations";
      else
      (w[i + 1] - w[i]) = -A*l*(
        der(p)*1/2*(drdp[i + 1] + drdp[i]) +
        1/6*(der(h[i])*(2*drdh[i] + drdh[i + 1]) +
             der(h[i + 1])*(drdh[i] + 2*drdh[i + 1]))) "Mass balance equations";
      end if;
    end for;

    // Energy equation FEM matrices
    Y[1, 1] =   rho[1]*  (l/12)*(3 - 2*alpha_sgn[1]) +
                rho[2]*  (l/12)*(1 - alpha_sgn[1]);
    Y[1, 2] =   rho[1]*  (l/12)*(1 - alpha_sgn[1]) +
                rho[2]*  (l/12)*(1 - 2*alpha_sgn[1]);
    Y[N, N-1] = rho[N-1]*(l/12)*(1 + 2*alpha_sgn[N]) +
                rho[N]*  (l/12)*(1 + alpha_sgn[N]);
    Y[N, N] =   rho[N-1]*(l/12)*(1 + alpha_sgn[N]) +
                rho[N]*  (l/12)*(3 + 2*alpha_sgn[N]);
    if N > 2 then
      for i in 2:N - 1 loop
        Y[i, i-1] = rho[i-1]*(l/12)*(1 + 2*alpha_sgn[i]) +
                    rho[i]*  (l/12)*(1 + alpha_sgn[i]);
        Y[i, i]   = rho[i-1]*(l/12)*(1 + alpha_sgn[i]) +
                    rho[i]*  (l/12)*6 +
                    rho[i+1]*(l/12)*(1 - alpha_sgn[i]);
        Y[i, i+1] = rho[i]*  (l/12)*(1 - alpha_sgn[i]) +
                    rho[i+1]*(l/12)*(1 - 2*alpha_sgn[i]);
        Y[1, i+1] = 0;
        Y[N, i-1] = 0;
        for j in 1:(i - 2) loop
          Y[i, j] = 0;
        end for;
        for j in (i + 2):N loop
          Y[i, j] = 0;
        end for;
      end for;
    end if;

    for i in 1:N loop
      for j in 1:N loop
        YY[i, j] = if (i <> j) then 0 else sum(Y[:, j]);
      end for;
    end for;

    M[1, 1]   = (4 - 3*alpha_sgn[1])*l/12;
    M[1, 2]   = (2 - 3*alpha_sgn[1])*l/12;
    M[N, N-1] = (2 + 3*alpha_sgn[N])*l/12;
    M[N, N]   = (4 + 3*alpha_sgn[N])*l/12;
    if N > 2 then
      for i in 2:N - 1 loop
        M[i, i-1] = (2 + 3*alpha_sgn[i])*l/12;
        M[i, i]   = 8*l/12;
        M[i, i+1] = (2 - 3*alpha_sgn[i])*l/12;
        M[1, i+1] = 0;
        M[N, i-1] = 0;
        for j in 1:(i - 2) loop
          M[i, j] = 0;
        end for;
        for j in (i + 2):N loop
          M[i, j] = 0;
        end for;
      end for;
    end if;

    B[1, 1] =   (w[1]*   (3*alpha_sgn[1] - 4) + w[2]*(3*alpha_sgn[1] - 2))/12;
    B[1, 2] =   (w[1]*   (4 - 3*alpha_sgn[1]) + w[2]*(2 - 3*alpha_sgn[1]))/12;
    B[N, N] =   (w[N-1]* (2 + 3*alpha_sgn[N]) + w[N]*(4 + 3*alpha_sgn[N]))/12;
    B[N, N-1] = (-w[N-1]*(2 + 3*alpha_sgn[N]) - w[N]*(4 + 3*alpha_sgn[N]))/12;
    if N > 2 then
      for i in 2:N - 1 loop
        B[i, i-1] = (-w[i-1]*(2 + 3*alpha_sgn[i])  - w[i]*(4 + 3*alpha_sgn[i]))/12;
        B[i, i]   = (w[i-1] *(2 + 3* alpha_sgn[i]) + w[i]*6*alpha_sgn[i] +
                     w[i+1] *(3*alpha_sgn[i] - 2))/12;
        B[i, i+1] = (w[i]*(4 - 3*alpha_sgn[i]) + w[i+1]*(2 - 3*alpha_sgn[i]))/12;
        B[1, i+1] = 0;
        B[N, i-1] = 0;
        for j in 1:(i - 2) loop
          B[i, j] = 0;
        end for;
        for j in (i + 2):N loop
          B[i, j] = 0;
        end for;
      end for;
    end if;

    if Medium.singleState then
      G = zeros(N) "No influence of pressure";
    else
      G[1] = l/2*(1 - alpha_sgn[1]);
      G[N] = l/2*(1 + alpha_sgn[1]);
      if N > 2 then
        for i in 2:N - 1 loop
          G[i] = l;
        end for;
      end if;
    end if;

    // boundary condition matrices
    if regularizeBoundaryConditions then
      C[1, 1] = Functions.stepReg(
        infl.m_flow - wnom*wnf_bc,
        (1 - alpha_sgn[1]/2)*w[1],
        0,
        wnom*wnf_bc);
      C[N, N] = Functions.stepReg(
        outfl.m_flow - wnom*wnf_bc,
        -(1 + alpha_sgn[N]/2)*w[N],
        0,
        wnom*wnf_bc);
    else
      C[1, 1] = noEvent(if infl.m_flow >= 0 then (1 - alpha_sgn[1]/2)*w[1] else 0);
      C[N, N] = noEvent(if outfl.m_flow >= 0 then -(1 + alpha_sgn[N]/2)*w[N] else 0);
    end if;
    C[N, 1] = 0;
    C[1, N] = 0;
    if (N > 2) then
      for i in 2:(N - 1) loop
        C[1, i] = 0;
        C[N, i] = 0;
        for j in 1:N loop
          C[i, j] = 0;
        end for;
      end for;
    end if;

    if regularizeBoundaryConditions then
      K[1, 1] = Functions.stepReg(
        infl.m_flow - wnom*wnf_bc,
        (1 - alpha_sgn[1]/2)*inStream(infl.h_outflow),
        0,
        wnom*wnf_bc);
      K[N, N] = Functions.stepReg(
        outfl.m_flow - wnom*wnf_bc,
        -(1 + alpha_sgn[N]/2)*inStream(outfl.h_outflow),
        0,
        wnom*wnf_bc);
    else
      K[1, 1] = noEvent(if infl.m_flow >= 0 then (1 - alpha_sgn[1]/2)*inStream(infl.h_outflow) else 0);
      K[N, N] = noEvent(if outfl.m_flow >= 0 then -(1 + alpha_sgn[N]/2)*inStream(outfl.h_outflow) else 0);
    end if;
    K[N, 1] = 0;
    K[1, N] = 0;
    if (N > 2) then
      for i in 2:(N - 1) loop
        K[1, i] = 0;
        K[N, i] = 0;
        for j in 1:N loop
          K[i, j] = 0;
        end for;
      end for;
    end if;

    // Momentum and Mass balance equation matrices
    D[1] = l/2;
    D[N] = l/2;
    for i in 2:N - 1 loop
      D[i] = l;
    end for;
    if HydraulicCapacitance == HCtypes.Middle then
      D1 = l*(if N == 2 then {3/8,1/8} else if evenN then cat(
          1,
          {1/2},
          ones(max(0, div(N, 2) - 2)),
          {7/8,1/8},
          zeros(div(N, 2) - 1)) else cat(
          1,
          {1/2},
          ones(div(N, 2) - 1),
          {1/2},
          zeros(div(N, 2))));
      D2 = l*(if N == 2 then {1/8,3/8} else if evenN then cat(
          1,
          zeros(div(N, 2) - 1),
          {1/8,7/8},
          ones(max(div(N, 2) - 2, 0)),
          {1/2}) else cat(
          1,
          zeros(div(N, 2)),
          {1/2},
          ones(div(N, 2) - 1),
          {1/2}));
    elseif HydraulicCapacitance == HCtypes.Upstream then
      D1 = zeros(N);
      D2 = D;
    elseif HydraulicCapacitance == HCtypes.Downstream then
      D1 = D;
      D2 = zeros(N);
    else
      assert(false, "Unsupported HydraulicCapacitance option");
    end if;

    connect(wall,heatTransfer.wall);

    Q = Nt*omega*D*phi "Total heat flow through lateral boundary";
    Mtot = Nt*D*rho*A "Total mass of fluid";
    Tr = noEvent(Mtot/max(abs(infl.m_flow), Modelica.Constants.eps))
      "Residence time";
  initial equation
    if initOpt == Choices.Init.Options.noInit then
      // do nothing
    elseif initOpt == Choices.Init.Options.fixedState then
      if not noInitialPressure then
        p = pstart;
      end if;
      h = hstart;
    elseif initOpt == Choices.Init.Options.steadyState then
      der(h) = zeros(N);
      if (not Medium.singleState) and not noInitialPressure then
        der(p) = 0;
      end if;
    elseif initOpt == Choices.Init.Options.steadyStateNoP then
      der(h) = zeros(N);
      assert(false, "initOpt = steadyStateNoP deprecated, use steadyState and noInitialPressure",AssertionLevel.warning);
    elseif initOpt == Choices.Init.Options.steadyStateNoT and not Medium.singleState then
      der(p) = 0;
    else
      assert(false, "Unsupported initialisation option");
    end if;
    annotation (
      Diagram(graphics),
      Icon(graphics={Text(extent={{-100,-60},{100,-100}},textString="%name")}),
      Documentation(info="<HTML>
<p>This model describes the flow of water or steam in a rigid tube. The basic modelling assumptions are:
<ul><li>The fluid state is always one-phase (i.e. subcooled liquid or superheated steam).
<li>Uniform velocity is assumed on the cross section, leading to a 1-D distributed parameter model.
<li>Turbulent friction is always assumed; a small linear term is added to avoid numerical singularities at zero flowrate. The friction effects are not accurately computed in the laminar and transitional flow regimes, which however should not be an issue in most applications using water or steam as a working fluid.
<li>The model is based on dynamic mass, momentum, and energy balances. The dynamic momentum term can be switched off, to avoid the fast oscillations that can arise from its coupling with the mass balance (sound wave dynamics).
<li>The longitudinal heat diffusion term is neglected.
<li>The energy balance equation is written by assuming a uniform pressure distribution; the pressure drop is lumped either at the inlet or at the outlet.
<li>The fluid flow can exchange thermal power through the lateral surface, which is represented by the <tt>wall</tt> connector. The actual heat flux must be computed by a connected component (heat transfer computation module).
</ul>
<p>The mass, momentum, and energy balance equation are discretised with the finite element method. The state variables are one pressure, one flowrate (optional) and N specific enthalpies.
<p>The turbulent friction factor can be either assumed as a constant, or computed by Colebrook's equation. In the former case, the friction factor can be supplied directly, or given implicitly by a specified operating point. In any case, the multiplicative correction coefficient <tt>Kfc</tt> can be used to modify the friction coefficient, e.g. to fit experimental data.
<p>A small linear pressure drop is added to avoid numerical singularities at low or zero flowrate. The <tt>wnom</tt> parameter must be always specified: the additional linear pressure drop is such that it is equal to the turbulent pressure drop when the flowrate is equal to <tt>wnf*wnom</tt> (the default value is 1% of the nominal flowrate). Increase <tt>wnf</tt> if numerical instabilities occur in tubes with very low pressure drops.
<p>Flow reversal is fully supported.
<p><b>Modelling options</b></p>
<p>Thermal variables (enthalpy, temperature, density) are computed in <tt>N</tt> equally spaced nodes, including the inlet (node 1) and the outlet (node N); <tt>N</tt> must be greater or equal than 2.
<p>The dynamic momentum term is included or neglected depending on the <tt>DynamicMomentum</tt> parameter.
<p> Two parameters are available to tune the numerical method. The stabilisation coefficient <tt>alpha</tt> varies from 0.0 to 1.0; <tt>alpha=0.0</tt> corresponds to a non-stabilised method, which gives rise to non-physical oscillations; the default value of 1.0 corresponds to a stabilised method, with well-damped oscillations. The mass lumping coefficient (<tt>ML</tt>) allows to use a hybrid finite-element/finite-volume discretisation method for the dynamic matrix; the default value <tt>ML=0.0</tt> corresponds to a standard FEM model, <tt>ML=1.0</tt> corresponds to a full finite-volume method, with the associated numerical diffusion effects. Intermediate values can be used.
<p>The following options are available to specify the friction coefficient:
<ul><li><tt>FFtype = FFtypes.Kfnom</tt>: the hydraulic friction coefficient <tt>Kf</tt> is set directly to <tt>Kfnom</tt>.
<li><tt>FFtype = FFtypes.OpPoint</tt>: the hydraulic friction coefficient is specified by a nominal operating point (<tt>wnom</tt>,<tt>dpnom</tt>, <tt>rhonom</tt>).
<li><tt>FFtype = FFtypes.Cfnom</tt>: the friction coefficient is computed by giving the (constant) value of the Fanning friction factor <tt>Cfnom</tt>.
<li><tt>FFtype = FFtypes.Colebrook</tt>: the Fanning friction factor is computed by Colebrook's equation (assuming Re > 2100, e.g. turbulent flow).
<li><tt>FFtype = FFtypes.NoFriction</tt>: no friction is assumed across the pipe.</ul>
<p>If <tt>HydraulicCapacitance = 2</tt> (default option) then the mass buildup term depending on the pressure is lumped at the outlet, while the optional momentum buildup term depending on the flowrate is lumped at the inlet. If <tt>HydraulicCapacitance = 1</tt> the reverse takes place.
<p>Start values for pressure and flowrate are specified by <tt>pstart</tt>, <tt>wstart</tt>. The start values for the node enthalpies are linearly distributed from <tt>hstartin</tt> at the inlet to <tt>hstartout</tt> at the outlet.
<p>A bank of <tt>Nt</tt> identical tubes working in parallel can be modelled by setting <tt>Nt > 1</tt>. The geometric parameters always refer to a <i>single</i> tube.
<p>This models makes the temperature and external heat flow distributions visible through the <tt>wall</tt> connector. If other variables (e.g. the heat transfer coefficient) are needed by external components to compute the actual heat flow, the <tt>wall</tt> connector can be replaced by an extended version of the <tt>DHT</tt> connector.
</HTML>", revisions="<html>
<ul>
<li><i>24 Mar 2005</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       <tt>FFtypes</tt> package and <tt>NoFriction</tt> option added.</li>
<li><i>1 Mar 2005</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Residence time added.</li>
<li><i>16 Dec 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Standard medium definition added.</li>
<li><i>8 Oct 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Model now based on <tt>Flow1DBase</tt>.
<li><i>24 Sep 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Removed <tt>wstart</tt>, <tt>pstart</tt>. Added <tt>pstartin</tt>, <tt>pstartout</tt>.
<li><i>23 Jul 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Adapted to Modelica.Media.</li>
<li><i>1 Jul 2004</i>
    by <a href=\"mailto:francesco.schiavo@polimi.it\">Francesco Schiavo</a>:<br>
       Mass flow-rate spatial distribution treatment added.</li>
<li><i>15 Jan 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Computation of fluid velocity <i>u</i> added. Improved treatment of geometric parameters</li>
<li><i>1 Oct 2003</i>
    by <a href=\"mailto:francesco.schiavo@polimi.it\">Francesco Schiavo</a>:<br>
       First release.</li>
</ul>
</html>"));
  end Flow1DFEM;

  model Flow1DFEM2ph
    "1-dimensional fluid flow model for water/steam (finite elements)"
    extends BaseClasses.Flow1DBase(
      Nw = N,
      redeclare replaceable package Medium = StandardWater "Medium model"
        constrainedby Modelica.Media.Interfaces.PartialTwoPhaseMedium);
      replaceable model HeatTransfer =
        Thermal.HeatTransferFEM.IdealHeatTransfer
      constrainedby ThermoPower.Thermal.BaseClasses.DistributedHeatTransferFEM
      annotation (choicesAllMatching=true);
    HeatTransfer heatTransfer(
      redeclare package Medium = Medium,
      final Nf=N,
      final Nw=Nw,
      final Nt=Nt,
      final L=L,
      final A=A,
      final Dhyd=Dhyd,
      final omega=omega,
      final wnom=wnom/Nt,
      final w=w,
      final fluidState=fluidState) "Instantiated heat transfer model";

    ThermoPower.Thermal.DHTNodes wall(N=N) annotation (Dialog(enable=
            false), Placement(transformation(extent={{-40,40},{40,60}},
            rotation=0)));

    import ThermoPower.Choices.Flow1D.FFtypes;
    import ThermoPower.Choices.Flow1D.HCtypes;

    parameter Real alpha(
      min=0,
      max=2) = 1 "Numerical stabilization coefficient";
    parameter Real ML(
      min=0,
      max=1) = 0.2 "Mass Lumping Coefficient";
    constant SI.Acceleration g = Modelica.Constants.g_n;
    final parameter Boolean evenN=(div(N, 2)*2 == N)
      "The number of nodes is even";
    constant SI.Pressure pzero=10 "Small deltap for calculations";
    constant Medium.AbsolutePressure pc=Medium.fluidConstants[1].criticalPressure;
    constant SI.SpecificEnthalpy hzero=1e-3;

    Medium.ThermodynamicState fluidState[N]
      "Thermodynamic state of the fluid at the nodes";
    Medium.SaturationProperties sat "Properties of saturated fluid";
    Medium.ThermodynamicState dew "Thermodynamic state at dewpoint";
    Medium.ThermodynamicState bubble "Thermodynamic state at bubblepoint";
    SI.Length omega_hyd "Hydraulic perimeter (single tube)";
    Real dwdt "Dynamic momentum term";
    Medium.AbsolutePressure p "Fluid pressure";
    SI.Pressure Dpfric "Pressure drop due to friction";
    SI.Pressure Dpfric1
      "Pressure drop due to friction (from inlet to capacitance)";
    SI.Pressure Dpfric2
      "Pressure drop due to friction (from capacitance to outlet)";
    SI.Pressure Dpstat "Pressure drop due to static head";
    Medium.MassFlowRate w[N](start=wnom*ones(N)) "Mass flowrate (single tube)";
    SI.Velocity u[N] "Fluid velocity";
    SI.HeatFlux phi[N] "External heat flux";
    Medium.Temperature T[N] "Fluid temperature";
    Medium.SpecificEnthalpy h[N](start=hstart) "Fluid specific enthalpy";
    Medium.Density rho[N] "Fluid density";
    SI.SpecificVolume v[N] "Fluid specific volume";

    Medium.Temperature Ts "Saturation temperature";
    Medium.SpecificEnthalpy hl(start=Medium.bubbleEnthalpy(Medium.setSat_p(
          pstart))) "Saturated liquid specific enthalpy";
    Medium.SpecificEnthalpy hv(start=Medium.dewEnthalpy(Medium.setSat_p(pstart)))
      "Saturated vapour specific enthalpy";
    Real x[N] "Steam quality";
    Units.LiquidDensity rhol "Saturated liquid density";
    Units.GasDensity rhov "Saturated vapour density";

    Real Kf[N] "Friction coefficient";
    Real Cf[N] "Fanning friction factor";
    Real Phi[N] "Two-phase friction multiplier";
  protected
    SI.DerDensityByEnthalpy drdh[N] "Derivative of density by enthalpy";
    SI.DerDensityByPressure drdp[N] "Derivative of density by pressure";

    SI.DerDensityByPressure drl_dp
      "Derivative of liquid density by pressure just before saturation";
    SI.DerDensityByPressure drv_dp
      "Derivative of vapour density by pressure just before saturation";
    SI.DerDensityByEnthalpy drl_dh
      "Derivative of liquid density by enthalpy just before saturation";
    SI.DerDensityByEnthalpy drv_dh
      "Derivative of vapour density by enthalpy just before saturation";

    Real dhl "Derivative of saturated liquid enthalpy by pressure";
    Real dhv "Derivative of saturated vapour enthalpy by pressure";

    Real drl "Derivative of saturatd liquid density by pressure";
    Real drv "Derivative of saturated vapour density by pressure";

    SI.Density rhos[N - 1];
    Medium.MassFlowRate ws[N - 1];
    Real rs[N - 1];

    Real Y[N, N];
    Real YY[N, N];

    Real Y2ph[N, N];
    Real M[N, N];
    Real D[N];
    Real D1[N];
    Real D2[N];
    Real G[N];
    Real B[N, N];
    Real B2ph[N, N];
    Real C[N, N];
    Real K[N, N];

    Real by[8, N];
    Real beta[8, N];
    //coefficients matrix for 2-phases augmented FEM matrices
    Real alpha_sgn;

    Real gamma_rho[N - 1];
    Real gamma_w[N - 1];
    //coefficients for gamma functions

    Real a;
    Real b;
    Real betap;
    Real c;
    Real d;
    Real ee[N - 1];
    Real f[N - 1];

    Real dMbif[N - 1];
    Real dMmono[N - 1];

  equation
    //All equations are referred to a single tube

    // Selection of representative pressure variable
    if HydraulicCapacitance == HCtypes.Middle then
      p = infl.p - Dpfric1 - Dpstat/2;
    elseif HydraulicCapacitance == HCtypes.Upstream then
      p = infl.p;
    elseif HydraulicCapacitance == HCtypes.Downstream then
      p = outfl.p;
    else
      assert(false, "Unsupported HydraulicCapacitance option");
    end if;

    //Friction factor calculation
    omega_hyd = 4*A/Dhyd;
    for i in 1:N loop
      if FFtype == FFtypes.NoFriction then
        Cf[i] = 0;
      elseif FFtype == FFtypes.Cfnom then
        Cf[i] = Cfnom*Kfc;
      else
        assert(true, "Unsupported friction factor selection");
      end if;
      Kf[i] = Cf[i]*omega_hyd*L/(2*A^3)
        "Relationship between friction coefficient and Fanning friction factor";
    end for;

    //Dynamic Momentum [not] accounted for
    if DynamicMomentum then
      if HydraulicCapacitance == HCtypes.Upstream then
        dwdt = -der(outfl.m_flow)/Nt;
      else
        dwdt = der(infl.m_flow)/Nt;
      end if;

    else
      dwdt = 0;
    end if;

    //Momentum balance equation
    L/A*dwdt + (outfl.p - infl.p) + Dpstat + Dpfric = 0;

    w[1] = infl.m_flow/Nt;
    w[N] = -outfl.m_flow/Nt;

    Dpfric = Dpfric1 + Dpfric2 "Total pressure drop due to friction";

    if FFtype == FFtypes.NoFriction then
      Dpfric1 = 0;
      Dpfric2 = 0;
    else
      Dpfric1 = homotopy(sum(Kf[i]/L*squareReg(w[i], wnom/Nt*wnf)*D1[i]/rho[i]*
        Phi[i] for i in 1:N), dpnom/2/(wnom/Nt)*w[1])
        "Pressure drop from inlet to capacitance";
      Dpfric2 = homotopy(sum(Kf[i]/L*squareReg(w[i], wnom/Nt*wnf)*D2[i]/rho[i]*
        Phi[i] for i in 1:N), dpnom/2/(wnom/Nt)*w[N])
        "Pressure drop from capacitance to outlet";
    end if "Pressure drop due to friction";

    for i in 1:N loop
      if FFtype == FFtypes.NoFriction or noEvent(h[i] <= hl or h[i] >= hv) then
        Phi[i] = 1;
      else
        // Chisholm-Laird formulation of Martinelli-Lockhart correlation for turbulent-turbulent flow
        // Phi_l^2 = 1 + 20/Xtt + 1/Xtt^2
        // same fixed Fanning friction factor Cfnom is assumed for liquid and vapour, so Xtt = (rhov/rhol)^0.5 * (1-x)/x
        Phi[i] = rho[i]/rhol*((1 - x[i])^2 + 20*sqrt(rhol/rhov)*x[i]*(1 - x[i])
           + rhol/rhov*x[i]^2);
      end if;
    end for;

    Dpstat = if abs(dzdx) < 1e-6 then 0 else g*dzdx*rho*D
      "Pressure drop due to static head";

    //Energy balance equations
    l/12*((1 - ML)*Y + ML*YY + 0*Y2ph)*der(h) + (1/A)*(B + 0*B2ph)*h + C*h/A =
      der(p)*G + M*(omega/A)*phi + K*w/A;

    //  (Ts,rhol,rhov,hl,hv,drl_dp,drv_dp,drl_dh,drv_dh,dhl,dhv,drl,drv) =
    //  propsat_p_2der(noEvent(min(p, pc - pzero)));

    sat = Medium.setSat_p(p);
    Ts = Medium.saturationTemperature_sat(sat);
    bubble = Medium.setBubbleState(sat);
    dew = Medium.setDewState(sat);
    rhol = Medium.bubbleDensity(sat);
    rhov = Medium.dewDensity(sat);
    hl = Medium.bubbleEnthalpy(sat);
    hv = Medium.dewEnthalpy(sat);
    drl = Medium.dBubbleDensity_dPressure(sat);
    drv = Medium.dDewDensity_dPressure(sat);
    dhl = Medium.dBubbleEnthalpy_dPressure(sat);
    dhv = Medium.dDewEnthalpy_dPressure(sat);
    drl_dp = Medium.density_derp_h(bubble);
    drv_dp = Medium.density_derp_h(dew);
    drl_dh = Medium.density_derh_p(bubble);
    drv_dh = Medium.density_derh_p(dew);

    a = ((hv - hl)*(rhol^2*drv + rhov^2*drl) + rhov*rhol*(rhol - rhov)*(dhv -
      dhl))/(rhol - rhov)^2;
    betap = ((rhol - rhov)*(rhov*dhv - rhol*dhl) + (hv - hl)*(rhol*drv - rhov*
      drl))/(rhol - rhov)^2;
    b = a*c + d*betap;
    c = (rhov*hv - rhol*hl)/(rhol - rhov);
    d = -rhol*rhov*(hv - hl)/(rhol - rhov);

    //Computation of fluid properties
    for j in 1:N loop
      fluidState[j] = Medium.setState_phX(p, h[j]);
      T[j] = Medium.temperature(fluidState[j]);
      rho[j] = Medium.density(fluidState[j]);
      drdp[j] = if Medium.singleState then 0 else Medium.density_derp_h(
        fluidState[j]);
      drdh[j] = Medium.density_derh_p(fluidState[j]);
      v[j] = 1/rho[j];
      u[j] = w[j]/(rho[j]*A);
      x[j] = noEvent(min(max((h[j] - hl)/(hv - hl), 0), 1));
    end for;

    //Boundary Values
    h[1] = infl.h_outflow;
    h[N] = outfl.h_outflow;
    phi = heatTransfer.phi_f;
    connect(wall, heatTransfer.wall);

    alpha_sgn = alpha*sign(infl.m_flow - outfl.m_flow);

    //phase change determination
    for i in 1:N - 1 loop
      (w[i] - w[i + 1]) = dMmono[i] + dMbif[i];
      if noEvent(abs(h[i + 1] - h[i]) < hzero) then

        rs[i] = 0;
        rhos[i] = 0;
        gamma_rho[i] = 0;

        gamma_w[i] = 0;
        ws[i] = 0;

        dMmono[i] = A*l*(der(p)*1/2*(drdp[i + 1] + drdp[i]) + 1/6*(der(h[i])*(2
          *drdh[i] + drdh[i + 1]) + der(h[i + 1])*(drdh[i] + 2*drdh[i + 1])));

        dMbif[i] = 0;

        ee[i] = 0;
        f[i] = 0;

      elseif noEvent((h[i] < hl) and (h[i + 1] >= hl) and (h[i + 1] <= hv)) then
        //liquid - two phase

        rs[i] = (hl - h[i])/(h[i + 1] - h[i]);
        rhos[i] = rhol;
        gamma_rho[i] = (rhos[i] - rho[i]*(1 - rs[i]) - rho[i + 1]*rs[i]);

        gamma_w[i] = (ws[i] - w[i]*(1 - rs[i]) - w[i + 1]*rs[i]);

        (w[i] - ws[i]) = dMmono[i];

        dMmono[i] = A*rs[i]*l*(der(p)*1/2*(drl_dp + drdp[i]) + 1/6*(der(h[i])*(
          2*drdh[i] + drl_dh) + (der(h[i])*(1 - rs[i]) + der(h[i + 1])*rs[i])*(
          drdh[i] + 2*drl_dh)));

        dMbif[i] = A*(1 - rs[i])*l/(h[i + 1] - hl)*(der(p)*((b - a*c)*(h[i + 1]
           - hl)/((c + h[i + 1])*(c + hl)) + a*log((c + h[i + 1])/(c + hl))) +
          ((d*f[i] - d*c*ee[i])*(h[i + 1] - hl)/((c + h[i + 1])*(c + hl)) + d*
          ee[i]*log((c + h[i + 1])/(c + hl))));

        ee[i] = (der(h[i + 1]) - (der(h[i + 1])*rs[i] + der(h[i])*(1 - rs[i])))
          /(h[i + 1] - hl);
        f[i] = ((der(h[i + 1])*rs[i] + der(h[i])*(1 - rs[i]))*h[i + 1] - der(h[
          i + 1])*hl)/(h[i + 1] - hl);

      elseif noEvent((h[i] >= hl) and (h[i] <= hv) and (h[i + 1] < hl)) then
        //two phase-liquid

        rs[i] = (hl - h[i])/(h[i + 1] - h[i]);
        rhos[i] = rhol;
        gamma_rho[i] = (rhos[i] - rho[i]*(1 - rs[i]) - rho[i + 1]*rs[i]);

        gamma_w[i] = (ws[i] - w[i]*(1 - rs[i]) - w[i + 1]*rs[i]);

        (w[i] - ws[i]) = dMbif[i];

        dMmono[i] = A*(1 - rs[i])*l*(der(p)*1/2*(drdp[i + 1] + drl_dp) + 1/6*(
          der(h[i])*(2*drl_dh + drdh[i + 1]) + (der(h[i + 1])*rs[i] + der(h[i])
          *(1 - rs[i]))*(drl_dh + 2*drdh[i + 1])));

        dMbif[i] = A*rs[i]*l/(hl - h[i])*(der(p)*((b - a*c)*(hl - h[i])/((c +
          hl)*(c + h[i])) + a*log((c + hl)/(c + h[i]))) + ((d*f[i] - d*c*ee[i])
          *(hl - h[i])/((c + hl)*(c + h[i])) + d*ee[i]*log((c + hl)/(c + h[i]))));

        ee[i] = ((der(h[i + 1])*rs[i] + der(h[i])*(1 - rs[i])) - der(h[i]))/(hl
           - h[i]);
        f[i] = (der(h[i])*hl - (der(h[i + 1])*rs[i] + der(h[i])*(1 - rs[i]))*h[
          i])/(hl - h[i]);

      elseif noEvent((h[i] >= hl) and (h[i] <= hv) and (h[i + 1] > hv)) then
        //two phase - vapour

        rs[i] = (hv - h[i])/(h[i + 1] - h[i]);
        rhos[i] = rhov;
        gamma_rho[i] = (rhos[i] - rho[i]*(1 - rs[i]) - rho[i + 1]*rs[i]);

        gamma_w[i] = (ws[i] - w[i]*(1 - rs[i]) - w[i + 1]*rs[i]);
        (w[i] - ws[i]) = dMbif[i];

        dMmono[i] = A*(1 - rs[i])*l*(der(p)*1/2*(drdp[i + 1] + drv_dp) + 1/6*(
          der(h[i])*(2*drv_dh + drdh[i + 1]) + (der(h[i + 1])*rs[i] + der(h[i])
          *(1 - rs[i]))*(drv_dh + 2*drdh[i + 1])));

        dMbif[i] = A*rs[i]*l/(hv - h[i])*(der(p)*((b - a*c)*(hv - h[i])/((c +
          hv)*(c + h[i])) + a*log((c + hv)/(c + h[i]))) + ((d*f[i] - d*c*ee[i])
          *(hv - h[i])/((c + hv)*(c + h[i])) + d*ee[i]*log((c + hv)/(c + h[i]))));

        ee[i] = ((der(h[i + 1])*rs[i] + der(h[i])*(1 - rs[i])) - der(h[i]))/(hv
           - h[i]);
        f[i] = (der(h[i])*hv - (der(h[i + 1])*rs[i] + der(h[i])*(1 - rs[i]))*h[
          i])/(hv - h[i]);

      elseif noEvent((h[i] > hv) and (h[i + 1] >= hl) and (h[i + 1] <= hv)) then
        // vapour - two phase

        rs[i] = (hv - h[i])/(h[i + 1] - h[i]);
        rhos[i] = rhov;
        gamma_rho[i] = (rhos[i] - rho[i]*(1 - rs[i]) - rho[i + 1]*rs[i]);

        gamma_w[i] = (ws[i] - w[i]*(1 - rs[i]) - w[i + 1]*rs[i]);
        (w[i] - ws[i]) = dMmono[i];

        dMmono[i] = A*rs[i]*l*(der(p)*1/2*(drv_dp + drdp[i]) + 1/6*(der(h[i])*(
          2*drdh[i] + drv_dh) + (der(h[i])*(1 - rs[i]) + der(h[i + 1])*rs[i])*(
          drdh[i] + 2*drv_dh)));

        dMbif[i] = A*(1 - rs[i])*(der(p)*((b - a*c)*(h[i + 1] - hv)/((c + h[i
           + 1])*(c + hv)) + a*log((c + h[i + 1])/(c + hv))) + ((d*f[i] - d*c*
          ee[i])*(h[i + 1] - hv)/((c + h[i + 1])*(c + hv)) + d*ee[i]*log((c + h[
          i + 1])/(c + hv))));

        ee[i] = (der(h[i + 1]) - (der(h[i + 1])*rs[i] + der(h[i])*(1 - rs[i])))
          /(h[i + 1] - hv);
        f[i] = ((der(h[i + 1])*rs[i] + der(h[i])*(1 - rs[i]))*h[i + 1] - der(h[
          i + 1])*hv)/(h[i + 1] - hv);

      elseif noEvent((h[i] >= hl) and (h[i] <= hv) and (h[i + 1] >= hl) and (h[
          i + 1] <= hv)) then
        //two phase

        rs[i] = 0;
        rhos[i] = 0;
        gamma_rho[i] = 0;

        gamma_w[i] = 0;

        ws[i] = 0;

        dMmono[i] = 0;

        dMbif[i] = A*l/(h[i + 1] - h[i])*(der(p)*((b - a*c)*(h[i + 1] - h[i])/(
          (c + h[i + 1])*(c + h[i])) + a*log((c + h[i + 1])/(c + h[i]))) + ((d*
          f[i] - d*c*ee[i])*(h[i + 1] - h[i])/((c + h[i + 1])*(c + h[i])) + d*
          ee[i]*log((c + h[i + 1])/(c + h[i]))));

        ee[i] = (der(h[i + 1]) - der(h[i]))/(h[i + 1] - h[i]);
        f[i] = (der(h[i])*h[i + 1] - der(h[i + 1])*h[i])/(h[i + 1] - h[i]);

      elseif noEvent(((h[i] < hl) and (h[i + 1] < hl)) or ((h[i] > hv) and (h[i
           + 1] > hv))) then
        //single-phase

        rs[i] = 0;
        rhos[i] = 0;
        gamma_rho[i] = 0;

        gamma_w[i] = 0;
        ws[i] = 0;

        dMmono[i] = A*l*(der(p)*1/2*(drdp[i + 1] + drdp[i]) + 1/6*(der(h[i])*(2
          *drdh[i] + drdh[i + 1]) + der(h[i + 1])*(drdh[i] + 2*drdh[i + 1])));
        dMbif[i] = 0;

        ee[i] = 0;
        f[i] = 0;
      else
        //double transition (not supported!)
        assert(0 > 1,
          "Error: two phase transitions between two adiacent nodes. Try increasing the number of nodes");
        rs[i] = 0;
        rhos[i] = 0;
        gamma_rho[i] = 0;

        gamma_w[i] = 0;
        ws[i] = 0;

        dMmono[i] = 0;
        dMbif[i] = 0;

        ee[i] = 0;
        f[i] = 0;
      end if;
    end for;

    // Energy equation FEM matrices

    Y[1, 1] = rho[1]*(3 - 2*alpha_sgn) + rho[2]*(1 - alpha_sgn);
    Y[1, 2] = rho[1]*(1 - alpha_sgn) + rho[2]*(1 - 2*alpha_sgn);
    Y[N, N] = rho[N - 1]*(alpha_sgn + 1) + rho[N]*(3 + 2*alpha_sgn);
    Y[N, N - 1] = rho[N - 1]*(1 + 2*alpha_sgn) + rho[N]*(1 + alpha_sgn);
    if N > 2 then
      for i in 2:N - 1 loop
        Y[i, i - 1] = rho[i - 1]*(1 + 2*alpha_sgn) + rho[i]*(1 + alpha_sgn);
        Y[i, i] = rho[i - 1]*(1 + alpha_sgn) + rho[i]*6 + rho[i + 1]*(1 -
          alpha_sgn);
        Y[i, i + 1] = rho[i]*(1 - alpha_sgn) + rho[i + 1]*(1 - 2*alpha_sgn);
        Y[1, i + 1] = 0;
        Y[N, i - 1] = 0;
        for j in 1:(i - 2) loop
          Y[i, j] = 0;
        end for;
        for j in (i + 2):N loop
          Y[i, j] = 0;
        end for;
      end for;
    end if;

    for i in 1:N loop
      for j in 1:N loop
        YY[i, j] = if (i <> j) then 0 else sum(Y[:, j]);
      end for;
    end for;

    M[1, 1] = l/3 - l*alpha_sgn/4;
    M[N, N] = l/3 + l*alpha_sgn/4;
    M[1, 2] = l/6 - l*alpha_sgn/4;
    M[N, (N - 1)] = l/6 + l*alpha_sgn/4;
    if N > 2 then
      for i in 2:N - 1 loop
        M[i, i - 1] = l/6 + l*alpha_sgn/4;
        M[i, i] = 2*l/3;
        M[i, i + 1] = l/6 - l*alpha_sgn/4;
        M[1, i + 1] = 0;
        M[N, i - 1] = 0;
        for j in 1:(i - 2) loop
          M[i, j] = 0;
        end for;
        for j in (i + 2):N loop
          M[i, j] = 0;
        end for;
      end for;
    end if;

    B[1, 1] = (-1/3 + alpha_sgn/4)*w[1] + (-1/6 + alpha_sgn/4)*w[2];
    B[1, 2] = (1/3 - alpha_sgn/4)*w[1] + (1/6 - alpha_sgn/4)*w[2];
    B[N, N] = (1/6 + alpha_sgn/4)*w[N - 1] + (1/3 + alpha_sgn/4)*w[N];
    B[N, N - 1] = (-1/6 - alpha_sgn/4)*w[N - 1] + (-1/3 - alpha_sgn/4)*w[N];
    if N > 2 then
      for i in 2:N - 1 loop
        B[i, i - 1] = (-1/6 - alpha_sgn/4)*w[i - 1] + (-1/3 - alpha_sgn/4)*w[i];
        B[i, i] = (1/6 + alpha_sgn/4)*w[i - 1] + (alpha_sgn/2)*w[i] + (-1/6 +
          alpha_sgn/4)*w[i + 1];
        B[i, i + 1] = (1/3 - alpha_sgn/4)*w[i] + (1/6 - alpha_sgn/4)*w[i + 1];
        B[1, i + 1] = 0;
        B[N, i - 1] = 0;
        for j in 1:(i - 2) loop
          B[i, j] = 0;
        end for;
        for j in (i + 2):N loop
          B[i, j] = 0;
        end for;
      end for;
    end if;

    G[1] = l/2*(1 - alpha_sgn);
    G[N] = l/2*(1 + alpha_sgn);
    if N > 2 then
      for i in 2:N - 1 loop
        G[i] = l;
      end for;
    end if;

    //boundary conditions

    C[1, 1] = if noEvent(infl.m_flow >= 0) then (1 - alpha_sgn/2)*w[1] else 0;
    C[N, N] = if noEvent(outfl.m_flow >= 0) then -(1 + alpha_sgn/2)*w[N] else 0;
    C[N, 1] = 0;
    C[1, N] = 0;
    if (N > 2) then
      for i in 2:(N - 1) loop
        C[1, i] = 0;
        C[N, i] = 0;
        for j in 1:N loop
          C[i, j] = 0;
        end for;
      end for;
    end if;

    K[1, 1] = if noEvent(infl.m_flow >= 0) then (1 - alpha_sgn/2)*inStream(infl.h_outflow)
       else 0;
    K[N, N] = if noEvent(outfl.m_flow >= 0) then -(1 + alpha_sgn/2)*inStream(
      outfl.h_outflow) else 0;
    K[N, 1] = 0;
    K[1, N] = 0;
    if (N > 2) then
      for i in 2:(N - 1) loop
        K[1, i] = 0;
        K[N, i] = 0;
        for j in 1:N loop
          K[i, j] = 0;
        end for;
      end for;
    end if;

    // Momentum and Mass balance equation matrices
    D[1] = l/2;
    D[N] = l/2;
    for i in 2:N - 1 loop
      D[i] = l;
    end for;
    if HydraulicCapacitance == HCtypes.Middle then
      D1 = l*(if N == 2 then {3/8,1/8} else if evenN then cat(
          1,
          {1/2},
          ones(max(0, div(N, 2) - 2)),
          {7/8,1/8},
          zeros(div(N, 2) - 1)) else cat(
          1,
          {1/2},
          ones(div(N, 2) - 1),
          {1/2},
          zeros(div(N, 2))));
      D2 = l*(if N == 2 then {1/8,3/8} else if evenN then cat(
          1,
          zeros(div(N, 2) - 1),
          {1/8,7/8},
          ones(max(div(N, 2) - 2, 0)),
          {1/2}) else cat(
          1,
          zeros(div(N, 2)),
          {1/2},
          ones(div(N, 2) - 1),
          {1/2}));
    elseif HydraulicCapacitance == HCtypes.Upstream then
      D1 = zeros(N);
      D2 = D;
    elseif HydraulicCapacitance == HCtypes.Downstream then
      D1 = D;
      D2 = zeros(N);
    else
      assert(false, "Unsupported HydraulicCapacitance option");
    end if;

    by[1, 1] = 0;
    by[2, 1] = 0;
    by[3, 1] = l/12*rs[1]*(6 - 8*rs[1] + 3*rs[1]^2 + alpha_sgn*(2*rs[1] - 3));
    by[4, 1] = -l/12*(1 - rs[1])^2*(2*alpha_sgn + 3*rs[1] - 3);
    by[5, 1] = -l/12*rs[1]^2*(2*alpha_sgn + 3*rs[1] - 4);
    by[6, 1] = -l/12*(1 - rs[1])*(3*rs[1]^2 - 2*rs[1] + 2*alpha_sgn*rs[1] +
      alpha_sgn - 1);
    by[7, 1] = 0;
    by[8, 1] = 0;
    by[1, N] = l/12*rs[N - 1]^2*(2*alpha_sgn + 3*rs[N - 1]);
    by[2, N] = l/12*(1 - rs[N - 1])*(1 + alpha_sgn + 2*rs[N - 1] + 2*alpha_sgn*
      rs[N - 1] + 3*rs[N - 1]^2);
    by[3, N] = 0;
    by[4, N] = 0;
    by[5, N] = 0;
    by[6, N] = 0;
    by[7, N] = l/12*rs[N - 1]*(alpha_sgn*(3 - 2*rs[N - 1]) + rs[N - 1]*(4 - 3*
      rs[N - 1]));
    by[8, N] = l/12*(1 - rs[N - 1])^2*(2*alpha_sgn + 3*rs[N - 1] + 1);
    if N > 2 then
      for i in 2:N - 1 loop
        by[1, i] = l/12*rs[i - 1]^2*(2*alpha_sgn + 3*rs[i - 1]);
        by[2, i] = l/12*(1 - rs[i - 1])*(1 + alpha_sgn + 2*rs[i - 1] + 2*
          alpha_sgn*rs[i - 1] + 3*rs[i - 1]^2);
        by[3, i] = l/12*rs[i]*(6 - 8*rs[i] + 3*rs[i]^2 + alpha_sgn*(2*rs[i] - 3));
        by[4, i] = -l/12*(1 - rs[i])^2*(2*alpha_sgn + 3*rs[i] - 3);
        by[5, i] = -l/12*rs[i]^2*(2*alpha_sgn + 3*rs[i] - 4);
        by[6, i] = -l/12*(1 - rs[i])*(3*rs[i]^2 - 2*rs[i] + 2*alpha_sgn*rs[i]
           + alpha_sgn - 1);
        by[7, i] = l/12*rs[i - 1]*(alpha_sgn*(3 - 2*rs[i - 1]) + rs[i - 1]*(4
           - 3*rs[i - 1]));
        by[8, i] = l/12*(1 - rs[i - 1])^2*(2*alpha_sgn + 3*rs[i - 1] + 1);
      end for;
    end if;

    //additional 2 phases Y-matrix
    Y2ph[1, 1] = (gamma_rho[1]*by[3, 1] + gamma_rho[1]*by[4, 1]);
    Y2ph[1, 2] = (gamma_rho[1]*by[5, 1] + gamma_rho[1]*by[6, 1]);
    Y2ph[N, N] = (gamma_rho[N - 1]*by[1, N] + gamma_rho[N - 1]*by[2, N]);
    Y2ph[N, N - 1] = (gamma_rho[N - 1]*by[7, N] + gamma_rho[N - 1]*by[8, N]);
    if N > 2 then
      for i in 2:N - 1 loop
        Y2ph[i, i - 1] = (gamma_rho[i - 1]*by[7, i] + gamma_rho[i - 1]*by[8, i]);
        Y2ph[i, i] = (gamma_rho[i - 1]*by[1, i] + gamma_rho[i - 1]*by[2, i]) +
          (gamma_rho[i]*by[3, i] + gamma_rho[i]*by[4, i]);
        Y2ph[i, i + 1] = (gamma_rho[i]*by[5, i] + gamma_rho[i]*by[6, i]);
        Y2ph[1, i + 1] = 0;
        Y2ph[N, i - 1] = 0;
        for j in 1:(i - 2) loop
          Y2ph[i, j] = 0;
        end for;
        for j in (i + 2):N loop
          Y2ph[i, j] = 0;
        end for;
      end for;
    end if;

    //computation of beta functions for additional matrices
    beta[1, 1] = 0;
    beta[2, 1] = 0;
    beta[3, 1] = 1/12*rs[1]*(3*alpha_sgn + 4*rs[1] - 6);
    beta[4, 1] = 1/12*(1 - rs[1])*(3*alpha_sgn + 4*rs[1] - 4);
    beta[5, 1] = -beta[3, 1];
    beta[6, 1] = -beta[4, 1];
    beta[7, 1] = 0;
    beta[8, 1] = 0;
    beta[1, N] = 1/12*rs[N - 1]*(3*alpha_sgn + 4*rs[N - 1]);
    beta[2, N] = 1/12*(1 - rs[N - 1])*(3*alpha_sgn + 4*rs[N - 1] + 2);
    beta[3, N] = 0;
    beta[4, N] = 0;
    beta[5, N] = 0;
    beta[6, N] = 0;
    beta[7, N] = -beta[1, N];
    beta[8, N] = -beta[2, N];
    if N > 2 then
      for i in 2:N - 1 loop
        beta[1, i] = 1/12*rs[i - 1]*(3*alpha_sgn + 4*rs[i - 1]);
        beta[2, i] = 1/12*(1 - rs[i - 1])*(3*alpha_sgn + 4*rs[i - 1] + 2);
        beta[3, i] = 1/12*rs[i]*(3*alpha_sgn + 4*rs[i] - 6);
        beta[4, i] = 1/12*(1 - rs[i])*(3*alpha_sgn + 4*rs[i] - 4);
        beta[5, i] = -beta[3, i];
        beta[6, i] = -beta[4, i];
        beta[7, i] = -beta[1, i];
        beta[8, i] = -beta[2, i];
      end for;
    end if;

    //additional 2 phases B-matrix
    B2ph[1, 1] = (gamma_w[1]*beta[3, 1] + gamma_w[1]*beta[4, 1]);
    B2ph[1, 2] = (gamma_w[1]*beta[5, 1] + gamma_w[1]*beta[6, 1]);
    B2ph[N, N] = (gamma_w[N - 1]*beta[1, N] + gamma_w[N - 1]*beta[2, N]);
    B2ph[N, N - 1] = (gamma_w[N - 1]*beta[7, N] + gamma_w[N - 1]*beta[8, N]);
    if N > 2 then
      for i in 2:N - 1 loop
        B2ph[i, i - 1] = (gamma_w[i - 1]*beta[7, i] + gamma_w[i - 1]*beta[8, i]);
        B2ph[i, i] = (gamma_w[i - 1]*beta[1, i] + gamma_w[i - 1]*beta[2, i]) +
          (gamma_w[i]*beta[3, i] + gamma_w[i]*beta[4, i]);
        B2ph[i, i + 1] = (gamma_w[i]*beta[5, i] + gamma_w[i]*beta[6, i]);
        B2ph[1, i + 1] = 0;
        B2ph[N, i - 1] = 0;
        for j in 1:(i - 2) loop
          B2ph[i, j] = 0;
        end for;
        for j in (i + 2):N loop
          B2ph[i, j] = 0;
        end for;
      end for;
    end if;
    Q = Nt*omega*D*phi "Total heat flow through lateral boundary";
    Tr = noEvent(sum(rho)*A*l/max(infl.m_flow/Nt, Modelica.Constants.eps));
  initial equation
    if initOpt == Choices.Init.Options.noInit then
      // do nothing
    elseif initOpt == Choices.Init.Options.fixedState then
      if not noInitialPressure then
        p = pstart;
      end if;
      h = hstart;
    elseif initOpt == Choices.Init.Options.steadyState then
      der(h) = zeros(N);
      if (not Medium.singleState) and not noInitialPressure then
        der(p) = 0;
      end if;
    elseif initOpt == Choices.Init.Options.steadyStateNoP then
      der(h) = zeros(N);
      assert(false, "initOpt = steadyStateNoP deprecated, use steadyState and noInitialPressure",AssertionLevel.warning);
    elseif initOpt == Choices.Init.Options.steadyStateNoT and not Medium.singleState then
      der(p) = 0;
    else
      assert(false, "Unsupported initialisation option");
    end if;
    annotation (
      Diagram(graphics),
      Icon(graphics={Text(extent={{-100,-40},{100,-80}}, textString="%name")}),
      Documentation(info="<HTML>
<p>This model describes the flow of water or steam in a rigid tube. The basic modelling assumptions are:
<ul><li>The fluid state is either one-phase, or a two-phase mixture.
<li>In case of two-phase flow, the same velocity is assumed for both phases (homogeneous model).
<li>Uniform velocity is assumed on the cross section, leading to a 1-D distributed parameter model.
<li>Turbulent friction is always assumed; a small linear term is added to avoid numerical singularities at zero flowrate. The friction effects are not accurately computed in the laminar and transitional flow regimes, which however should not be an issue in most applications using water or steam as a working fluid.
<li>The model is based on dynamic mass, momentum, and energy balances. The dynamic momentum term can be switched off, to avoid the fast oscillations that can arise from its coupling with the mass balance (sound wave dynamics).
<li>The longitudinal heat diffusion term is neglected.
<li>The energy balance equation is written by assuming a uniform pressure distribution; the pressure drop is lumped either at the inlet or at the outlet.
<li>The fluid flow can exchange thermal power through the lateral surface, which is represented by the <tt>wall</tt> connector. The actual heat flux must be computed by a connected component (heat transfer computation module).
</ul>
<p>The mass, momentum, and energy balance equation are discretised with the Finite Element Method (Stabilised Galerkin Least Squares). The state variables are one pressure, one flowrate (optional) and N specific enthalpies.
<p>The turbulent friction factor can be either assumed as a constant, or computed by Colebrook's equation. In the former case, the friction factor can be supplied directly, or given implicitly by a specified operating point. In any case, the multiplicative correction coefficient <tt>Kfc</tt> can be used to modify the friction coefficient, e.g. to fit experimental data.
<p>A small linear pressure drop is added to avoid numerical singularities at low or zero flowrate. The <tt>wnom</tt> parameter must be always specified: the additional linear pressure drop is such that it is equal to the turbulent pressure drop when the flowrate is equal to <tt>wnf*wnom</tt> (the default value is 1% of the nominal flowrate). Increase <tt>wnf</tt> if numerical instabilities occur in tubes with very low pressure drops.
<p>Flow reversal is fully supported.
<p><b>Modelling options</b></p>
<p>Thermal variables (enthalpy, temperature, density) are computed in <tt>N</tt> equally spaced nodes, including the inlet (node 1) and the outlet (node N); <tt>N</tt> must be greater or equal than 2.
<p>The dynamic momentum term is included or neglected depending on the <tt>DynamicMomentum</tt> parameter.
<p> Two parameters are available to tune the numerical method. The stabilisation coefficient <tt>alpha</tt> varies from 0.0 to 1.0; <tt>alpha=0.0</tt> corresponds to a non-stabilised method, which gives rise to non-physical oscillations; the default value of 1.0 corresponds to a stabilised method, with well-damped oscillations. The mass lumping coefficient (<tt>ML</tt>) allows to use a hybrid finite-element/finite-volume discretisation method for the dynamic matrix; the default value <tt>ML=0.0</tt> corresponds to a standard FEM model, <tt>ML=1.0</tt> corresponds to a full finite-volume method, with the associated numerical diffusion effects. Intermediate values can be used.
<p>The following options are available to specify the friction coefficient:
<ul><li><tt>FFtype = FFtypes.Kfnom</tt>: the hydraulic friction coefficient <tt>Kf</tt> is set directly to <tt>Kfnom</tt>.
<li><tt>FFtype = FFtypes.OpPoint</tt>: the hydraulic friction coefficient is specified by a nominal operating point (<tt>wnom</tt>,<tt>dpnom</tt>, <tt>rhonom</tt>).
<li><tt>FFtype = FFtypes.Cfnom</tt>: the friction coefficient is computed by giving the (constant) value of the Fanning friction factor <tt>Cfnom</tt>.
<li><tt>FFtype = FFtypes.Colebrook</tt>: the Fanning friction factor is computed by Colebrook's equation (assuming Re > 2100, e.g. turbulent flow).
<li><tt>FFtype = FFtypes.NoFriction</tt>: no friction is assumed across the pipe.</ul><p>If <tt>HydraulicCapacitance = 2</tt> (default option) then the mass buildup term depending on the pressure is lumped at the outlet, while the optional momentum buildup term depending on the flowrate is lumped at the inlet. If <tt>HydraulicCapacitance = 1</tt> the reverse takes place.
<p>Start values for pressure and flowrate are specified by <tt>pstart</tt>, <tt>wstart</tt>. The start values for the node enthalpies are linearly distributed from <tt>hstartin</tt> at the inlet to <tt>hstartout</tt> at the outlet.
<p>A bank of <tt>Nt</tt> identical tubes working in parallel can be modelled by setting <tt>Nt > 1</tt>. The geometric parameters always refer to a <i>single</i> tube.
<p>This models makes the temperature and external heat flow distributions visible through the <tt>wall</tt> connector. If other variables (e.g. the heat transfer coefficient) are needed by external components to compute the actual heat flow, the <tt>wall</tt> connector can be replaced by an extended version of the <tt>DHT</tt> connector.
</HTML>", revisions="<html>
<ul>
<li><i>30 May 2005</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Initialisation support added.</li>
<li><i>24 Mar 2005</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       <tt>FFtypes</tt> package and <tt>NoFriction</tt> option added.
       <br>Residence time added</li>
<li><i>16 Dec 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Standard medium definition added.</li>
<li><i>8 Oct 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Model now based on <tt>Flow1DBase</tt>.
<li><i>24 Sep 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Removed <tt>wstart</tt>, <tt>pstart</tt>. Added <tt>pstartin</tt>, <tt>pstartout</tt>.
<li><i>23 Jul 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Adapted to Modelica.Media.</li>
<li><i>1 Jul 2004</i>
    by <a href=\"mailto:francesco.schiavo@polimi.it\">Francesco Schiavo</a>:<br>
       First release.</li>
</ul>
</html>
"));
  end Flow1DFEM2ph;

  model FlowJoin "Joins two water/steam flows"
    extends Icons.Water.FlowJoin;
    replaceable package Medium = StandardWater constrainedby
      Modelica.Media.Interfaces.PartialMedium "Medium model"
      annotation(choicesAllMatching = true);
    parameter Boolean allowFlowReversal=system.allowFlowReversal
      "= true to allow flow reversal, false restricts to design direction"
      annotation(Evaluate=true);
    outer ThermoPower.System system "System wide properties";
    constant SI.MassFlowRate wzero=1e-9
      "Small flowrate to avoid singularity in computing the outlet enthalpy";
    parameter Boolean rev_in1=allowFlowReversal "Allow flow reversal at in1"
      annotation (Evaluate=true);
    parameter Boolean rev_in2=allowFlowReversal "Allow flow reversal at in2"
      annotation (Evaluate=true);
    parameter Boolean rev_out=allowFlowReversal "Allow flow reversal at out"
      annotation (Evaluate=true);
    parameter Boolean checkFlowDirection=false "Check flow direction"
      annotation (Dialog(enable=not rev_in1 or not rev_in2 or not rev_out));
    FlangeB out(redeclare package Medium = Medium, m_flow(max=if
            allowFlowReversal then +Modelica.Constants.inf else 0)) annotation (
       Placement(transformation(extent={{40,-20},{80,20}}, rotation=0)));
    FlangeA in1(redeclare package Medium = Medium, m_flow(min=if
            allowFlowReversal then -Modelica.Constants.inf else 0)) annotation (
       Placement(transformation(extent={{-80,20},{-40,60}}, rotation=0)));
    FlangeA in2(redeclare package Medium = Medium, m_flow(min=if
            allowFlowReversal then -Modelica.Constants.inf else 0)) annotation (
       Placement(transformation(extent={{-80,-60},{-40,-20}}, rotation=0)));
  equation
    in1.m_flow + in2.m_flow + out.m_flow = 0 "Mass balance";
    in1.p = out.p;
    in2.p = out.p;

    // Energy balance
    out.h_outflow = homotopy(
      if (in2.m_flow < 0 and rev_in2) then
        inStream(in1.h_outflow)
      else if (in1.m_flow < 0 and rev_in1) then
         inStream(in2.h_outflow)
      else
        (inStream(in1.h_outflow)*(in1.m_flow + wzero) +
         inStream(in2.h_outflow)*(in2.m_flow + wzero))/
        (in1.m_flow + 2*wzero + in2.m_flow),
      (inStream(in1.h_outflow)*(in1.m_flow + wzero) +
       inStream(in2.h_outflow)*(in2.m_flow + wzero))/
      (in1.m_flow + 2*wzero + in2.m_flow));

    in1.h_outflow = homotopy(
      if (in2.m_flow < 0 and rev_in2) then
        inStream(out.h_outflow)
      else if (out.m_flow < 0 or not rev_out) then
        inStream(in2.h_outflow)
      else
        (inStream(out.h_outflow)*(out.m_flow + wzero) +
         inStream(in2.h_outflow)*(in2.m_flow + wzero))/
        (out.m_flow + 2*wzero + in2.m_flow),
      inStream(out.h_outflow));

    in2.h_outflow = homotopy(
      if (in1.m_flow < 0 and rev_in1) then
        inStream(out.h_outflow)
      else if (out.m_flow < 0 or not rev_out) then
        inStream(in1.h_outflow)
      else
        (inStream(out.h_outflow)*(out.m_flow + wzero) +
         inStream(in1.h_outflow)*(in1.m_flow + wzero))/
        (out.m_flow + 2*wzero + in1.m_flow),
      inStream(out.h_outflow));

    //Check flow direction
    assert(not checkFlowDirection or
      ((rev_in1 or in1.m_flow >= 0) and
       (rev_in2 or in2.m_flow >= 0) and
       (rev_out or out.m_flow <= 0)),
      "Flow reversal not supported");
    annotation (
      Icon(graphics),
      Documentation(info="<html>
<p>This component allows to join two separate flows into one. The model is based on mass and energy balance equations, without any mass or energy buildup, and without any pressure drop between the inlet and the outlets.</p>
<p>Since stream connectors are used in the library, this component is actually not necessary to handle a three-way connection. It can be used for a finer tuning of the simplified model for initialization using homotopy, in particularly hard-to-initialize systems, and it is included in the library for backwards compatibility.</p>
<h4>Modelling options</h4>
<p>If <code>rev_in1</code>, <code>rev_in2</code> or <code>rev_out</code> is true, the respective flows reversal is allowed. If at least ona among these parameters is false, it is possible to set <code>checkFlowDirection</code>.</p>
<p>If <code>checkFlowDirection</code> is true, when the flow reversal happen where it is not allowed, the error message is showed.</p>
</html>", revisions="<html>
<ul>
<li><i>30 Oct 2014</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Bug fixing.</li>
<li><i>23 May 2008</i>
    by <a>Luca Savoldelli</a>:<br>
       Allow flows reversal option added.</li>
<li><i>16 Dec 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Standard medium definition added.</li>
<li><i>1 Oct 2003</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       First release.</li>
</ul>
</html>
"),   Diagram(graphics));
  end FlowJoin;

  model FlowSplit "Splits a flow in two"
    extends Icons.Water.FlowSplit;
    replaceable package Medium = StandardWater constrainedby
      Modelica.Media.Interfaces.PartialMedium "Medium model"
      annotation(choicesAllMatching = true);
    parameter Boolean allowFlowReversal=system.allowFlowReversal
      "= true to allow flow reversal, false restricts to design direction"
      annotation(Evaluate=true);
    outer ThermoPower.System system "System wide properties";
    constant SI.MassFlowRate wzero=1e-9
      "Small flowrate to avoid singularity in computing the outlet enthalpy";
    parameter Boolean rev_in1=allowFlowReversal "Allow flow reversal at in1"
      annotation (Evaluate=true);
    parameter Boolean rev_out1=allowFlowReversal "Allow flow reversal at out1"
      annotation (Evaluate=true);
    parameter Boolean rev_out2=allowFlowReversal "Allow flow reversal at out2"
      annotation (Evaluate=true);
    parameter Boolean checkFlowDirection=false "Check flow direction"
      annotation (Dialog(enable=not rev_in1 or not rev_out1 or not rev_out2));
    FlangeA in1(redeclare package Medium = Medium, m_flow(min=if
            allowFlowReversal then -Modelica.Constants.inf else 0)) annotation (
       Placement(transformation(extent={{-80,-20},{-40,20}}, rotation=0)));
    FlangeB out1(redeclare package Medium = Medium, m_flow(max=if
            allowFlowReversal then +Modelica.Constants.inf else 0)) annotation (
       Placement(transformation(extent={{40,20},{80,60}}, rotation=0),
          iconTransformation(extent={{40,20},{80,60}})));
    FlangeB out2(redeclare package Medium = Medium, m_flow(max=if
            allowFlowReversal then +Modelica.Constants.inf else 0)) annotation (
       Placement(transformation(extent={{40,-60},{80,-20}}, rotation=0)));
  equation
    in1.m_flow + out1.m_flow + out2.m_flow = 0 "Mass balance";
    out1.p = in1.p;
    out2.p = in1.p;
    // Energy balance
    out1.h_outflow = homotopy(
      if (in1.m_flow < 0 and rev_in1) then
        inStream(out2.h_outflow)
      else if (out2.m_flow < 0 or not rev_out2) then
        inStream(in1.h_outflow)
      else
        (inStream(in1.h_outflow)*(in1.m_flow + wzero) +
         inStream(out2.h_outflow)*(out2.m_flow + wzero))/
        (in1.m_flow + 2*wzero + out2.m_flow),
      inStream(in1.h_outflow));

    out2.h_outflow = homotopy(
      if (in1.m_flow < 0 and rev_in1) then
        inStream(out1.h_outflow)
      else if (out1.m_flow < 0 or not rev_out1) then
        inStream(in1.h_outflow)
      else
        (inStream(in1.h_outflow)*(in1.m_flow + wzero) +
         inStream(out1.h_outflow)*(out1.m_flow + wzero))/
        (in1.m_flow + 2*wzero + out1.m_flow),
      inStream(in1.h_outflow));

    in1.h_outflow = homotopy(
      if (out1.m_flow < 0 or not rev_out1) then
         inStream(out2.h_outflow)
      else if (out2.m_flow < 0 or not rev_out2) then
         inStream(out1.h_outflow)
      else
        (inStream(out1.h_outflow)*(out1.m_flow + wzero) +
         inStream(out2.h_outflow)*(out2.m_flow + wzero))/
        (out1.m_flow + 2*wzero + out2.m_flow),
      inStream(in1.h_outflow));

    //Check flow direction
    assert(not checkFlowDirection or
     ((rev_in1 or in1.m_flow >= 0) and
      (rev_out1 or out1.m_flow <= 0) and
      (rev_out2 or out2.m_flow <= 0)),
      "Flow reversal not supported");
    annotation (
      Icon(graphics),
      Documentation(info="<html>
<p>This component allows to split a single flow in two ones. The model is based on mass and energy balance equations, without any mass or energy buildup, and without any pressure drop between the inlet and the outlets. </p>
<p>Since stream connectors are used in the library, this component is actually not necessary to handle a three-way connection. It can be used for a finer tuning of the simplified model for initialization using homotopy, in particularly hard-to-initialize systems, and it is included in the library for backwards compatibility.</p>
<h4>Modelling options</h4>
<p>If <code>rev_in1</code>, <code>rev_out1</code> or <code>rev_out2</code> is true, the respective flows reversal is allowed. If at least ona among these parameters is false, it is possible to set <code>checkFlowDirection</code>.</p>
<p>If <code>checkFlowDirection</code> is true, when the flow reversal happen where it is not allowed, the error message is showed.</p>
</html>", revisions="<html>
<ul>
<li><i>30 Oct 2014</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Bug fixing.</li>
<li><i>23 May 2008</i>
    by <a>Luca Savoldelli</a>:<br>
       Allow flows reversal option added.</li>
<li><i>16 Dec 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Standard medium definition added.</li>
<li><i>1 Oct 2003</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       First release.</li>
</ul>
</html>
"));
  end FlowSplit;

  model SensT "Temperature sensor for water-steam"
    extends Icons.Water.SensThrough;
    replaceable package Medium = StandardWater constrainedby
      Modelica.Media.Interfaces.PartialMedium "Medium model"
      annotation(choicesAllMatching = true);
    parameter Boolean allowFlowReversal=system.allowFlowReversal
      "= true to allow flow reversal, false restricts to design direction"
      annotation(Evaluate=true);
    outer ThermoPower.System system "System wide properties";
    Medium.SpecificEnthalpy h "Specific enthalpy of the fluid";
    Medium.ThermodynamicState fluidState "Thermodynamic state of the fluid";
    FlangeA inlet(redeclare package Medium = Medium, m_flow(min=if
            allowFlowReversal then -Modelica.Constants.inf else 0)) annotation (
       Placement(transformation(extent={{-80,-60},{-40,-20}}, rotation=0)));
    FlangeB outlet(redeclare package Medium = Medium, m_flow(max=if
            allowFlowReversal then +Modelica.Constants.inf else 0)) annotation (
       Placement(transformation(extent={{40,-60},{80,-20}}, rotation=0)));
    Modelica.Blocks.Interfaces.RealOutput T annotation (Placement(
          transformation(extent={{60,40},{100,80}}, rotation=0)));
  equation
    inlet.m_flow + outlet.m_flow = 0 "Mass balance";
    inlet.p = outlet.p "No pressure drop";
    // Set fluid properties
    h = homotopy(if not allowFlowReversal then inStream(inlet.h_outflow) else
      actualStream(inlet.h_outflow), inStream(inlet.h_outflow));
    fluidState = Medium.setState_phX(inlet.p, h);
    T = Medium.temperature(fluidState);

    // Boundary conditions
    inlet.h_outflow = inStream(outlet.h_outflow);
    inStream(inlet.h_outflow) = outlet.h_outflow;
    annotation (
      Diagram(graphics),
      Icon(graphics={Text(
            extent={{-40,84},{38,34}},
            lineColor={0,0,0},
            textString="T")}),
      Documentation(info="<HTML>
<p>This component can be inserted in a hydraulic circuit to measure the temperature of the fluid flowing through it.
<p>Flow reversal is supported.
</HTML>", revisions="<html>
<ul>
<li><i>16 Dec 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Standard medium definition added.</li>
<li><i>1 Jul 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Adapted to Modelica.Media.</li>
<li><i>1 Oct 2003</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       First release.</li>
</ul>
</html>"));
  end SensT;

  model SensT1 "Temperature sensor for water/steam flows, single port"
    extends ThermoPower.Icons.Water.SensP;
    replaceable package Medium = ThermoPower.Water.StandardWater constrainedby
      Modelica.Media.Interfaces.PartialMedium "Medium model"
      annotation(choicesAllMatching = true);
    Modelica.Blocks.Interfaces.RealOutput T annotation (Placement(
          transformation(extent={{60,40},{100,80}}, rotation=0)));
    FlangeA flange(redeclare package Medium = Medium, m_flow(min=0))
      annotation (Placement(transformation(extent={{-20,-60},{20,-20}},
            rotation=0)));
  equation
    flange.m_flow = 0;
    flange.h_outflow = 0;
    T = Medium.temperature(Medium.setState_phX(flange.p, inStream(flange.h_outflow)));
    annotation (
      Diagram(graphics),
      Icon(graphics={Text(
            extent={{-40,84},{38,34}},
            lineColor={0,0,0},
            textString="T")}),
      Documentation(info="<HTML>
<p>This component can be connected to any A-type or B-type connector to measure the pressure of the fluid flowing through it. In this case, it is possible to connect more than two <tt>Flange</tt> connectors together.
</HTML>", revisions="<html>
<ul>
<li><i>16 Dec 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Standard medium definition added.</li>
<li><i>1 Oct 2003</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       First release.</li>
</ul>
</html>"));
  end SensT1;

  model SensW "Mass Flowrate sensor for water/steam"
    extends Icons.Water.SensThrough;
    replaceable package Medium = StandardWater constrainedby
      Modelica.Media.Interfaces.PartialMedium "Medium model"
      annotation(choicesAllMatching = true);
    parameter Boolean allowFlowReversal=system.allowFlowReversal
      "= true to allow flow reversal, false restricts to design direction"
      annotation(Evaluate=true);
    outer ThermoPower.System system "System wide properties";
    FlangeA inlet(redeclare package Medium = Medium, m_flow(min=if
            allowFlowReversal then -Modelica.Constants.inf else 0)) annotation (
       Placement(transformation(extent={{-80,-60},{-40,-20}}, rotation=0)));
    FlangeB outlet(redeclare package Medium = Medium, m_flow(max=if
            allowFlowReversal then +Modelica.Constants.inf else 0)) annotation (
       Placement(transformation(extent={{40,-60},{80,-20}}, rotation=0)));
    Modelica.Blocks.Interfaces.RealOutput w annotation (Placement(
          transformation(extent={{60,40},{100,80}}, rotation=0)));
  equation
    inlet.m_flow + outlet.m_flow = 0 "Mass balance";

    // Boundary conditions
    inlet.p = outlet.p;
    inlet.h_outflow = inStream(outlet.h_outflow);
    inStream(inlet.h_outflow) = outlet.h_outflow;
    w = inlet.m_flow;
    annotation (
      Diagram(graphics),
      Icon(graphics={Text(
            extent={{-42,92},{40,32}},
            lineColor={0,0,0},
            textString="w")}),
      Documentation(info="<HTML>
<p>This component can be inserted in a hydraulic circuit to measure the flowrate of the fluid flowing through it.
<p>Flow reversal is supported.
</HTML>", revisions="<html>
<ul>
<li><i>16 Dec 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Standard medium definition added.</li>
<li><i>1 Oct 2003</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       First release.</li>
</ul>
</html>
"));
  end SensW;

  model SensP "Pressure sensor for water/steam flows"
    extends Icons.Water.SensP;
    replaceable package Medium = StandardWater constrainedby
      Modelica.Media.Interfaces.PartialMedium "Medium model"
      annotation(choicesAllMatching = true);
    Modelica.Blocks.Interfaces.RealOutput p annotation (Placement(
          transformation(extent={{60,40},{100,80}}, rotation=0)));
    FlangeA flange(redeclare package Medium = Medium, m_flow(min=0))
      annotation (Placement(transformation(extent={{-20,-60},{20,-20}},
            rotation=0)));
  equation
    flange.m_flow = 0;
    p = flange.p;
    flange.h_outflow = 0;
    annotation (
      Diagram(graphics),
      Icon(graphics={Text(
            extent={{-42,92},{44,36}},
            lineColor={0,0,0},
            textString="p")}),
      Documentation(info="<HTML>
<p>This component can be connected to any A-type or B-type connector to measure the pressure of the fluid flowing through it. In this case, it is possible to connect more than two <tt>Flange</tt> connectors together.
</HTML>", revisions="<html>
<ul>
<li><i>16 Dec 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Standard medium definition added.</li>
<li><i>1 Oct 2003</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       First release.</li>
</ul>
</html>"));
  end SensP;

  model Accumulator "Water-Gas Accumulator"
    extends ThermoPower.Icons.Water.Accumulator;
    replaceable package Medium = StandardWater constrainedby
      Modelica.Media.Interfaces.PartialMedium "Liquid medium model"
      annotation(choicesAllMatching = true);
    Medium.ThermodynamicState liquidState "Thermodynamic state of the liquid";

    parameter SI.Volume V "Total volume";
    parameter SI.Volume Vl0 "Water nominal volume (at reference level)";
    parameter SI.Area A "Cross Sectional Area";

    parameter SI.Height zl0
      "Height of water reference level over inlet/outlet connectors";
    parameter SI.Height zl_start "Water start level (relative to reference)"
      annotation (Dialog(tab="Initialisation"));
    parameter Medium.SpecificEnthalpy hl_start "Water start specific enthalpy"
      annotation (Dialog(tab="Initialisation"));
    parameter SI.Pressure pg_start "Gas start pressure"
      annotation (Dialog(tab="Initialisation"));
    parameter Units.AbsoluteTemperature Tg_start=300 "Gas start temperature"
      annotation (Dialog(tab="Initialisation"));
    parameter SI.CoefficientOfHeatTransfer gamma_ex=50
      "Water-Gas heat transfer coefficient";
    parameter SI.Temperature Tgin=300 "Inlet gas temperature";
    parameter SI.MolarMass MM=29e-3 "Gas molar mass";
    parameter SI.MassFlowRate wg_out0 "Nominal gas outlet flowrate";
    parameter Units.AbsoluteTemperature Tg0=300 "Nominal gas temperature";
    parameter Units.AbsolutePressure pg0 "Nominal gas pressure";
    parameter Boolean allowFlowReversal=system.allowFlowReversal
      "= true to allow flow reversal, false restricts to design direction"
      annotation(Evaluate=true);
    outer ThermoPower.System system "System wide properties";
    parameter Choices.Init.Options initOpt=system.initOpt
      "Initialisation option"
      annotation (Dialog(tab="Initialisation"));
    parameter Boolean noInitialPressure=false
      "Remove initial equation on pressure"
      annotation (Dialog(tab="Initialisation"),choices(checkBox=true));
  protected
    constant SI.Acceleration g=Modelica.Constants.g_n;
    constant Real R=Modelica.Constants.R "Universal gas constant";
    parameter SI.SpecificHeatCapacityAtConstantPressure cpg=(7/2)*Rstar
      "Cp of gas";
    parameter SI.SpecificHeatCapacityAtConstantVolume cvg=(5/2)*Rstar
      "Cv of gas";
    parameter Real Rstar=R/MM "Gas constant";
    parameter Real K=wg_out0/(pg0*sqrt(Tg0)) "Gas outlet flow coefficient";
  public
    Medium.MassFlowRate wl_in "Water inflow mass flow rate";
    Medium.MassFlowRate wl_out "Water outflow mass flow rate";
    SI.Height zl(start=zl_start) "Water level (relative to reference)";
    Medium.SpecificEnthalpy hl_in "Water inlet specific enthalpy";
    Medium.SpecificEnthalpy hl_out "Water outlet specific enthalpy";
    Medium.SpecificEnthalpy hl(start=hl_start, stateSelect=StateSelect.prefer)
      "Water internal specific enthalpy";
    SI.Volume Vl "Volume occupied by water";
    SI.Mass Mg "Mass of gas";
    Medium.AbsolutePressure pf "Water Pressure at the inlet/outlet flanges";
    SI.EnergyFlowRate Qp "Water-Gas heat flow";
    SI.MassFlowRate wg_in "Gas inflow mass flow rate";
    SI.MassFlowRate wg_out "Gas outflow mass flow rate";
    Units.GasDensity rhog(start=pg_start*MM/(R*Tg_start)) "Gas density";
    Medium.Temperature Tg(start=Tg_start) "Gas temperature";
    SI.Volume Vg "Volume occupied by gas";
    Medium.AbsolutePressure pg(start=pg_start) "Gas pressure";
    Units.LiquidDensity rho "Density of the water";
    Modelica.Blocks.Interfaces.RealInput GasInfl annotation (Placement(
          transformation(extent={{-84,80},{-64,100}}, rotation=0)));
    FlangeA WaterInfl(redeclare package Medium = Medium, m_flow(min=if
            allowFlowReversal then -Modelica.Constants.inf else 0)) annotation (
       Placement(transformation(extent={{-44,-100},{-24,-80}}, rotation=0)));
    FlangeB WaterOutfl(redeclare package Medium = Medium, m_flow(max=if
            allowFlowReversal then +Modelica.Constants.inf else 0)) annotation (
       Placement(transformation(extent={{24,-100},{44,-80}}, rotation=0)));
    Modelica.Blocks.Interfaces.RealInput OutletValveOpening annotation (
        Placement(transformation(
          origin={44,90},
          extent={{-10,-10},{10,10}},
          rotation=270)));
  equation

    //Equations for water and gas volumes and exchanged thermal power
    Vl = Vl0 + A*zl;
    Vg = V - Vl;
    Qp = gamma_ex*A*(Medium.temperature(liquidState) - Tg);

    // Boundary conditions
    // (Thermal effects of the water going out of the accumulator are neglected)
    hl_in = homotopy(if not allowFlowReversal then inStream(WaterInfl.h_outflow)
       else if wl_in >= 0 then inStream(WaterInfl.h_outflow) else hl, inStream(
      WaterInfl.h_outflow));
    hl_out = homotopy(if not allowFlowReversal then hl else if wl_out >= 0
       then inStream(WaterOutfl.h_outflow) else hl, hl);
    WaterInfl.h_outflow = inStream(WaterOutfl.h_outflow);
    WaterOutfl.h_outflow = inStream(WaterInfl.h_outflow);
    wl_in = WaterInfl.m_flow;
    wl_out = WaterOutfl.m_flow;
    WaterInfl.p = pf;
    WaterOutfl.p = pf;

    rho*A*der(zl) = wl_in + wl_out
      "Water mass balance (density variations neglected)";
    rho*Vl*der(hl) - Vl*der(pg) - pg*der(Vl) = wl_in*(hl_in - hl) + wl_out*(
      hl_out - hl) - Qp "Water energy balance";

    // Set liquid properties
    liquidState = Medium.setState_phX(pg, hl);
    rho = Medium.density(liquidState);

    pf = pg + rho*g*(zl + zl0) "Stevino's law";

    wg_in = GasInfl "Gas inlet mass-flow rate";

    //Gas outlet mass-flow rate
    wg_out = -OutletValveOpening*K*pg*sqrt(Tg);

    pg = rhog*Rstar*Tg "Gas state equation";
    Mg = Vg*rhog "Gas mass";
    der(Mg) = wg_in + wg_out "Gas mass balance";
    rhog*Vg*cpg*der(Tg) = wg_in*cpg*(Tgin - Tg) + Vg*der(pg) + Qp
      "Gas energy balance";
  initial equation
    if initOpt == Choices.Init.Options.noInit then
      // do nothing
    elseif initOpt == Choices.Init.Options.fixedState then
      zl = zl_start;
      Tg = Tg_start;
      hl = hl_start;
      if not noInitialPressure then
        pg = pg_start;
      end if;
    elseif initOpt == Choices.Init.Options.steadyState then
      zl = zl_start;
      der(Tg) = 0;
      der(hl) = 0;
      der(pg) = 0;
    elseif initOpt == Choices.Init.Options.steadyStateNoP then
      zl = zl_start;
      der(Tg) = 0;
      der(hl) = 0;
    else
      assert(false, "Unsupported initialisation option");
    end if;
    annotation (
      Diagram(graphics),
      Icon(graphics),
      Documentation(info="<HTML>
<p>This model describes a water-gas accumulator (the gas is modeled as ideal bi-atomic). <p>
Water flows in and out through the interfaces at the component bottom (flow reversal supported). <p>
The gas is supposed to flow in at constant temperature (parameter <tt>Tgin</tt>) and with variable flow-rate (<tt>GasInfl</tt> signal port), and to flow out by a valve operating in choked condition; the valve coefficient is determined by the working point at full opening (<tt>wg_out0,Tg0, Pg0</tt>) while the valve opening (in the range <tt>0-1</tt>) is an input signal (<tt>OutletValveOpening</tt> signal port).
<p><b>Dimensional parameters</b></p>
<ul>
<li><tt>V</tt>: accumulator total volume;
<li><tt>Vl0</tt>: volume occupied by water at the nominal level (reference value);
<li><tt>zl0</tt>: height of water nominal level above the water connectors;
<li><tt>A</tt>: cross-sectional area at actual water level;
</ul>
</HTML>", revisions="<html>
<ul>
<li><i>30 May 2005</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Initialisation support added.</li>
<li><i>16 Dec 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Standard medium definition added.</li>
<li><i>18 Jun 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Adapted to Modelica.Media.</li>
<li><i>5 Feb 2004</i>
    by <a href=\"mailto:francesco.schiavo@polimi.it\">Francesco Schiavo</a>:<br>
       First release.</li>
</ul>
</html>"));
  end Accumulator;

  model Drum "Drum for circulation boilers"
    extends Icons.Water.Drum;
    replaceable package Medium = StandardWater constrainedby
      Modelica.Media.Interfaces.PartialTwoPhaseMedium "Medium model"
      annotation(choicesAllMatching = true);
    Medium.ThermodynamicState liquidState "Thermodynamic state of the liquid";
    Medium.ThermodynamicState vapourState "Thermodynamic state of the vapour";
    Medium.SaturationProperties sat;
    parameter SI.Length rint=0 "Internal radius";
    parameter SI.Length rext=0 "External radius";
    parameter SI.Length L=0 "Length";
    parameter SI.HeatCapacity Cm=0 "Total Heat Capacity of the metal wall"
      annotation (Evaluate=true);
    parameter SI.Temperature Text=293 "External atmospheric temperature";
    parameter SI.Time tauev=15 "Time constant of bulk evaporation";
    parameter SI.Time tauc=15 "Time constant of bulk condensation";
    parameter Real Kcs=0 "Surface condensation coefficient [kg/(s.m2.K)]";
    parameter Real Ks=0 "Surface heat transfer coefficient [W/(m2.K)]";
    parameter SI.CoefficientOfHeatTransfer gext=0
      "Heat transfer coefficient between metal wall and external atmosphere";
    parameter SI.CoefficientOfHeatTransfer gl=200
      "Heat transfer coefficient between metal wall and liquid phase"
      annotation (Evaluate=true);
    parameter SI.CoefficientOfHeatTransfer gv=200
      "Heat transfer coefficient between metal wall and vapour phase"
      annotation (Evaluate=true);
    parameter SI.ThermalConductivity lm=20 "Metal wall thermal conductivity";
    parameter Real afd=0.05 "Ratio of feedwater in downcomer flowrate";
    parameter Real avr=1.2 "Phase separation efficiency coefficient";
    parameter Integer DrumOrientation=0 "0: Horizontal; 1: Vertical";
    parameter Boolean allowFlowReversal=system.allowFlowReversal
      "= true to allow flow reversal, false restricts to design direction"
      annotation(Evaluate=true);
    outer ThermoPower.System system "System wide properties";
    parameter Medium.AbsolutePressure pstart=1e5 "Pressure start value"
      annotation (Dialog(tab="Initialisation"));
    parameter Medium.SpecificEnthalpy hlstart=Medium.bubbleEnthalpy(Medium.setSat_p(
        pstart)) "Liquid enthalpy start value"
      annotation (Dialog(tab="Initialisation"));
    parameter Medium.SpecificEnthalpy hvstart=Medium.dewEnthalpy(Medium.setSat_p(
        pstart)) "Vapour enthalpy start value"
      annotation (Dialog(tab="Initialisation"));
    parameter Medium.Temperature Tmstart = Medium.saturationTemperature(pstart)
      "Wall temperature start value"
      annotation (Dialog(tab="Initialisation"));
    parameter SI.Length ystart=0 "Start level value"
      annotation (Dialog(tab="Initialisation"));
    parameter Choices.Init.Options initOpt=system.initOpt
      "Initialisation option"
      annotation (Dialog(tab="Initialisation"));
    parameter Boolean noInitialPressure=false
      "Remove initial equation on pressure"
      annotation (Dialog(tab="Initialisation"),choices(checkBox=true));
    constant SI.Acceleration g=Modelica.Constants.g_n;
    constant Real pi=Modelica.Constants.pi;

    SI.Volume Vv(start=pi*rint^2*L/2) "Volume occupied by the vapour";
    SI.Volume Vl(start=pi*rint^2*L/2) "Volume occupied by the liquid";
    Medium.AbsolutePressure p(start=pstart, stateSelect=StateSelect.prefer)
      "Surface pressure";
    SI.SpecificEnthalpy hl(start=hlstart, stateSelect=StateSelect.prefer)
      "Liquid specific enthalpy";
    SI.SpecificEnthalpy hv(start=hvstart, stateSelect=StateSelect.prefer)
      "Vapour specific enthalpy";
    SI.SpecificEnthalpy hrv
      "Specific enthalpy of vapour from the risers after separation";
    SI.SpecificEnthalpy hrl
      "Specific enthalpy of liquid from the risers after separation";
    SI.SpecificEnthalpy hls "Specific enthalpy of saturated liquid";
    SI.SpecificEnthalpy hvs "Specific enthalpy of saturated vapour";
    SI.SpecificEnthalpy hf "Specific enthalpy of feedwater";
    SI.SpecificEnthalpy hd "Specific enthalpy of liquid to the downcomers";
    SI.SpecificEnthalpy hvout "Specific enthalpy of steam at the outlet";
    SI.SpecificEnthalpy hr "Specific enthalpy of fluid from the risers";
    Medium.MassFlowRate wf "Mass flowrate of feedwater";
    Medium.MassFlowRate wd "Mass flowrate to the downcomers";
    Medium.MassFlowRate wb "Mass flowrate of blowdown";
    Medium.MassFlowRate wr "Mass flowrate from the risers";
    Medium.MassFlowRate wrl "Mass flowrate of liquid from the risers";
    Medium.MassFlowRate wrv "Mass flowrate of vapour from the risers";
    Medium.MassFlowRate wv "Mass flowrate of steam at the outlet";
    Medium.MassFlowRate wc "Mass flowrate of bulk condensation";
    Medium.MassFlowRate wcs "Mass flowrate of surface condensation";
    Medium.MassFlowRate wev "Mass flowrate of bulk evaporation";
    Medium.Temperature Tl "Liquid temperature";
    Medium.Temperature Tv "Vapour temperature";
    Units.AbsoluteTemperature Tm(start=Tmstart,
        stateSelect=if Cm > 0 then StateSelect.prefer else StateSelect.default)
      "Wall temperature";
    Medium.Temperature Ts "Saturated water temperature";
    SI.Power Qmv "Heat flow from the wall to the vapour";
    SI.Power Qvl "Heat flow from the vapour to the liquid";
    SI.Power Qml "Heat flow from the wall to the liquid";
    SI.Power Qme "Heat flow from the wall to the atmosphere";
    SI.Mass Ml "Liquid mass";
    SI.Mass Mv "Vapour mass";
    SI.Energy El "Liquid internal energy";
    SI.Energy Ev "Vapour internal energy";
    Units.LiquidDensity rhol "Liquid density";
    Units.GasDensity rhov "Vapour density";
    SI.PerUnit xl "Mass fraction of vapour in the liquid volume";
    SI.PerUnit xv "Steam quality in the vapour volume";
    SI.PerUnit xr "Steam quality of the fluid from the risers";
    SI.PerUnit xrv "Steam quality of the separated steam from the risers";
    Real gml "Total heat transfer coefficient (wall-liquid)";
    Real gmv "Total heat transfer coefficient (wall-vapour)";
    Real a;
    SI.Length y(start=ystart, stateSelect=StateSelect.prefer)
      "Level (referred to the centreline)";
    SI.Area Aml "Surface of the wall-liquid interface";
    SI.Area Amv "Surface of the wall-vapour interface";
    SI.Area Asup "Surface of the liquid-vapour interface";
    SI.Area Aext "External drum surface";
    FlangeA feedwater(
      p(start=pstart),
      h_outflow(start=hlstart),
      redeclare package Medium = Medium,
      m_flow(min=if allowFlowReversal then -Modelica.Constants.inf else 0))
      annotation (Placement(transformation(extent={{-114,-32},{-80,2}},
            rotation=0)));
    FlangeA riser(
      p(start=pstart),
      h_outflow(start=hlstart),
      redeclare package Medium = Medium,
      m_flow(min=if allowFlowReversal then -Modelica.Constants.inf else 0))
      annotation (Placement(transformation(extent={{60,-74},{96,-40}}, rotation=
             0)));
    FlangeB downcomer(
      p(start=pstart),
      h_outflow(start=hlstart),
      redeclare package Medium = Medium,
      m_flow(max=if allowFlowReversal then +Modelica.Constants.inf else 0))
      annotation (Placement(transformation(extent={{-88,-88},{-52,-52}},
            rotation=0)));
    FlangeB blowdown(
      p(start=pstart),
      h_outflow(start=hlstart),
      redeclare package Medium = Medium,
      m_flow(max=if allowFlowReversal then +Modelica.Constants.inf else 0))
      annotation (Placement(transformation(extent={{-18,-116},{18,-80}},
            rotation=0)));
    FlangeB steam(
      p(start=pstart),
      h_outflow(start=hvstart),
      redeclare package Medium = Medium,
      m_flow(max=if allowFlowReversal then +Modelica.Constants.inf else 0))
      annotation (Placement(transformation(extent={{40,52},{76,88}}, rotation=0)));
  equation
    der(Mv) = wrv + wev - wv - wc - wcs "Vapour volume mass balance";
    der(Ml) = wf + wrl + wc + wcs - wd - wb - wev "Liquid volume mass balance";
    der(Ev) = wrv*hrv + (wev - wcs)*hvs - wc*hls - wv*hvout + Qmv - Qvl - p*der(
      Vv) "Vapour volume energy balance";
    der(El) = wf*hf + wrl*hrl + wc*hls + (wcs - wev)*hvs - wd*hd - wb*hl + Qml
       + Qvl - p*der(Vl) "Liquid volume energy balance";
    //Metal wall energy balance with singular cases
    if Cm > 0 and (gl > 0 or gv > 0) then
      Cm*der(Tm) = -Qml - Qmv - Qme "Metal wall dynamic energy balance";
    elseif (gl > 0 or gv > 0) then
      0 = -Qml - Qmv - Qme "Metal wall static energy balance";
    else
      Tm = 300 "Wall temperature doesn't matter";
    end if;
    Mv = Vv*rhov "Vapour volume mass";
    Ml = Vl*rhol "Liquid volume mass";
    Ev = hv*Mv - p*Vv "Vapour volume energy";
    El = hl*Ml - p*Vl "Liquid volume energy";
    wev = xl*rhol*Vl/tauev "Bulk evaporation flow rate in the liquid volume";
    wc = (1 - xv)*rhov*Vv/tauc
      "Bulk condensation flow rate in the vapour volume";
    wcs = Kcs*Asup*(Ts - Tl) "Surface condensation flow rate";
    Qme = gext*Aext*(Tm - Text)
      "Heat flow from metal wall to external environment";
    Qml = gml*Aml*(Tm - Tl) "Heat flow from metal wall to liquid volume";
    Qmv = gmv*Amv*(Tm - Tv) "Heat flow from metal wall to vapour volume";
    Qvl = Ks*Asup*(Tv - Ts) "Heat flow from vapour to liquid volume";
    xv = homotopy(if hv >= hvs then 1 else (hv - hls)/(hvs - hls), (hv - hls)/(
      hvs - hls)) "Steam quality in the vapour volume";
    xl = homotopy(if hl <= hls then 0 else (hl - hls)/(hvs - hls), 0)
      "Steam quality in the liquid volume";
    gml = if gl == 0 then 0 else 1/(1/gl + a*rint/lm)
      "Total Heat conductance metal-liquid";
    gmv = if gv == 0 then 0 else 1/(1/gv + a*rint/lm)
      "Total Heat conductance metal-vapour";
    a = rext^2/(rext^2 - rint^2)*log(rext/rint) - 0.5;
    if DrumOrientation == 0 then
      Vl = L*(rint^2*acos(-y/rint) + y*sqrt(rint^2 - y^2)) "Liquid volume";
      Aml = 2*Vl/L + 2*rint*acos(-y/rint)*L "Metal-liquid interface area";
      Asup = 2*sqrt(rint^2 - y^2)*L "Liquid-vapour interface area";
    else
      Vl = pi*rint^2*(y + L/2) "Liquid volume";
      Aml = pi*rint^2 + 2*pi*rint*(y + L/2) "Metal-liquid interface area";
      Asup = pi*rint^2 "Liquid-vapour interface area";
    end if;
    Vv = pi*rint^2*L - Vl "Vapour volume";
    Amv = 2*pi*rint*L + 2*pi*rint^2 - Aml "Metal-vapour interface area";
    Aext = 2*pi*rext^2 + 2*pi*rext*L "External metal surface area";

    // Fluid properties
    liquidState = Medium.setState_phX(p, hl);
    Tl = Medium.temperature(liquidState);
    rhol = Medium.density_ph(p,hl);
    vapourState = Medium.setState_phX(p, hv);
    Tv = Medium.temperature(vapourState);
    rhov = Medium.density_ph(p, hv);
    sat = Medium.setSat_p(p);
    hls = Medium.bubbleEnthalpy(sat);
    hvs = Medium.dewEnthalpy(sat);
    Ts = sat.Tsat;

    // Boundary conditions
    feedwater.p = p;
    feedwater.m_flow = wf;
    feedwater.h_outflow = hl;
    hf = homotopy(if not allowFlowReversal then inStream(feedwater.h_outflow)
       else noEvent(actualStream(feedwater.h_outflow)), inStream(feedwater.h_outflow));
    downcomer.p = p + rhol*g*y;
    downcomer.m_flow = -wd;
    downcomer.h_outflow = hd;
    hd = homotopy(if not allowFlowReversal then afd*hf + (1 - afd)*hl else
      noEvent(if wd >= 0 then afd*hf + (1 - afd)*hl else inStream(downcomer.h_outflow)),
      afd*hf + (1 - afd)*hl);
    blowdown.p = p;
    blowdown.m_flow = -wb;
    blowdown.h_outflow = hl;
    riser.p = p;
    riser.m_flow = wr;
    riser.h_outflow = hl;
    hrv = hls + xrv*(hvs - hls);
    xrv = homotopy(1 - (rhov/rhol)^avr, 1 - (Medium.dewDensity(Medium.setSat_p(
      pstart))/Medium.bubbleDensity(Medium.setSat_p(pstart)))^avr);
    hr = homotopy(if not allowFlowReversal then inStream(riser.h_outflow) else
      noEvent(actualStream(riser.h_outflow)), inStream(riser.h_outflow));
    xr = homotopy(if not allowFlowReversal then (if hr > hls then (hr - hls)/(
      hvs - hls) else 0) else noEvent(if wr >= 0 then (if hr > hls then (hr -
      hls)/(hvs - hls) else 0) else xl), (hr - hls)/(hvs - hls));
    hrl = homotopy(if not allowFlowReversal then (if hr > hls then hls else hr)
       else noEvent(if wr >= 0 then (if hr > hls then hls else hr) else hl),
      hls);
    wrv = homotopy(if not allowFlowReversal then xr*wr/xrv else noEvent(if wr
       >= 0 then xr*wr/xrv else 0), xr*wr/xrv);
    wrl = wr - wrv;
    steam.p = p;
    steam.m_flow = -wv;
    steam.h_outflow = hv;
    hvout = homotopy(if not allowFlowReversal then hv else noEvent(actualStream(
      steam.h_outflow)), hv);
  initial equation
    if initOpt == Choices.Init.Options.noInit then
      // do nothing
    elseif initOpt == Choices.Init.Options.fixedState then
      if not noInitialPressure then
        p = pstart;
      end if;
      hl = hlstart;
      hv = hvstart;
      y = ystart;
      if Cm > 0 and (gl > 0 or gv > 0) then
        Tm = Tmstart;
      end if;
    elseif initOpt == Choices.Init.Options.steadyState then
      der(p) = 0;
      der(hl) = 0;
      der(hv) = 0;
      der(y) = 0;
      if Cm > 0 and (gl > 0 or gv > 0) then
        der(Tm) = 0;
      end if;
    elseif initOpt == Choices.Init.Options.steadyStateNoP then
      der(hl) = 0;
      der(hv) = 0;
      der(y) = 0;
      if Cm > 0 and (gl > 0 or gv > 0) then
        der(Tm) = 0;
      end if;
    else
      assert(false, "Unsupported initialisation option");
    end if;
    annotation (
      Icon(graphics={
          Text(extent={{-150,26},{-78,0}}, textString="Feed"),
          Text(extent={{-180,-34},{-66,-58}}, textString="Downcomer"),
          Text(extent={{-38,-102},{46,-142}}, textString="Blowdown"),
          Text(extent={{52,-22},{146,-40}}, textString="Risers"),
          Text(extent={{-22,100},{50,80}}, textString="Steam")}),
      Documentation(info="<HTML>
<p>This model describes the cylindrical drum of a drum boiler, without assuming thermodynamic equilibrium between the liquid and vapour holdups. Connectors are provided for feedwater inlet, steam outlet, downcomer outlet, riser inlet, and blowdown outlet.
<p>The model is based on dynamic mass and energy balance equations of the liquid volume and vapour volume inside the drum. Mass and energy tranfer between the two phases is provided by bulk condensation and surface condensation of the vapour phase, and by bulk boiling of the liquid phase. Additional energy transfer can take place at the surface if the steam is superheated.
<p>The riser flowrate is separated before entering the drum, at the vapour pressure. The (saturated) liquid fraction goes into the liquid volume; the (wet) vapour fraction goes into the vapour volume, vith a steam quality depending on the liquid/vapour density ratio and on the <tt>avr</tt> parameter.
<p>The enthalpy of the liquid going to the downcomer is computed by assuming that a fraction of the total mass flowrate (<tt>afd</tt>) comes directly from the feedwater inlet. The pressure at the downcomer connector is equal to the vapour pressure plus the liquid head.
<p>The metal wall dynamics is taken into account, assuming uniform temperature. Heat transfer takes place between the metal wall and the liquid phase, vapour phase, and external atmosphere, the corresponding heat transfer coefficients being <tt>gl</tt>, <tt>gv</tt>, and <tt>gext</tt>.
<p>The drum level is referenced to the centreline.
<p>The start values of drum pressure, liquid specific enthalpy, vapour specific enthalpy, and metal wall temperature can be specified by setting the parameters <tt>pstart</tt>, <tt>hlstart</tt>, <tt>hvstart</tt>, <tt>Tmstart</tt>
<p><b>Modelling options</b></p>
<p>The following options are available to specify the orientation of the cylindrical drum:
<ul><li><tt>DrumOrientation = 0</tt>: horizontal axis.
<li><tt>DrumOrientation = 1</tt>: vertical axis.
</ul>
</HTML>", revisions="<html>
<ul>
<li><i>30 May 2005</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Initialisation support added.</li>
<li><i>16 Dec 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Standard medium definition added.</li>
<li><i>5 Jul 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Adapted to Modelica.Media.</li>
<li><i>1 Feb 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Improved equations for drum geometry.</li>
<li><i>1 Oct 2003</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       First release.</li>
</ul>
"),   Diagram(graphics));
  end Drum;

  model DrumEquilibrium
    extends Icons.Water.Drum;
    replaceable package Medium = StandardWater constrainedby
      Modelica.Media.Interfaces.PartialTwoPhaseMedium "Medium model"
      annotation(choicesAllMatching = true);
    parameter SI.Volume Vd "Drum internal volume";
    parameter SI.Mass Mm "Drum metal mass";
    parameter Medium.SpecificHeatCapacity cm
      "Specific heat capacity of the metal";
    parameter Boolean allowFlowReversal=system.allowFlowReversal
      "= true to allow flow reversal, false restricts to design direction"
      annotation(Evaluate=true);
    outer ThermoPower.System system "System wide properties";
    parameter SI.Pressure pstart "Pressure start value"
      annotation (Dialog(tab="Initialisation"));
    parameter SI.Volume Vlstart "Start value of drum water volume"
      annotation (Dialog(tab="Initialisation"));
    parameter Choices.Init.Options initOpt=system.initOpt
      "Initialisation option"
      annotation (Dialog(tab="Initialisation"));
    parameter Boolean noInitialPressure=false
      "Remove initial equation on pressure"
      annotation (Dialog(tab="Initialisation"),choices(checkBox=true));

    Medium.SaturationProperties sat "Saturation conditions";
    FlangeA feed(redeclare package Medium = Medium, m_flow(min=if
            allowFlowReversal then -Modelica.Constants.inf else 0)) annotation (
       Placement(transformation(extent={{-110,-64},{-70,-24}}, rotation=0)));
    FlangeB steam(redeclare package Medium = Medium, m_flow(max=if
            allowFlowReversal then +Modelica.Constants.inf else 0)) annotation (
       Placement(transformation(extent={{48,52},{88,92}}, rotation=0)));
    Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_a wall
      "Metal wall thermal port" annotation (Placement(transformation(extent={{-28,
              -100},{28,-80}}, rotation=0)));

    SI.Mass Ml "Liquid water mass";
    SI.Mass Mv "Steam mass";
    SI.Mass M "Total liquid+steam mass";
    SI.Energy E "Total energy";
    SI.Volume Vv(start = Vd - Vlstart) "Steam volume";
    SI.Volume Vl(
      start = Vlstart,
      stateSelect=StateSelect.prefer)
      "Liquid water total volume";
    Medium.AbsolutePressure p(
      start=pstart,
      stateSelect=StateSelect.prefer)
      "Drum pressure";
    Medium.MassFlowRate qf "Feedwater mass flowrate";
    Medium.MassFlowRate qs "Steam mass flowrate";
    SI.HeatFlowRate Q "Heat flow to the risers";
    Medium.SpecificEnthalpy hf "Feedwater specific enthalpy";
    Medium.SpecificEnthalpy hl "Specific enthalpy of saturated liquid";
    Medium.SpecificEnthalpy hv "Specific enthalpy of saturated steam";
    Medium.Temperature Ts "Saturation temperature";
    Units.LiquidDensity rhol "Density of saturated liquid";
    Units.GasDensity rhov "Density of saturated steam";
  equation
    Ml = Vl*rhol "Mass of liquid";
    Mv = Vv*rhov "Mass of vapour";
    M = Ml + Mv "Total mass";
    E = Ml*hl + Mv*hv - p*Vd + Mm*cm*Ts "Total energy";
    Ts = sat.Tsat "Saturation temperature";
    der(M) = qf - qs "Mass balance";
    der(E) = Q + qf*hf - qs*hv "Energy balance";
    Vl + Vv = Vd "Total volume";

    // Boundary conditions
    p = feed.p;
    p = steam.p;
    if not allowFlowReversal then
      hf = inStream(feed.h_outflow);
    else
      // assume flow is entering during simplified initialization
      hf = homotopy(
        actualStream(feed.h_outflow),
        inStream(feed.h_outflow));
    end if;
    feed.m_flow = qf;
    -steam.m_flow = qs;
    feed.h_outflow = hl;
    steam.h_outflow = hv;
    Q = wall.Q_flow;
    wall.T = Ts;

    // Fluid properties
    sat.psat = p;
    sat.Tsat = Medium.saturationTemperature(p);
    rhol = Medium.bubbleDensity(sat);
    rhov = Medium.dewDensity(sat);
    hl = Medium.bubbleEnthalpy(sat);
    hv = Medium.dewEnthalpy(sat);
  initial equation
    if initOpt == Choices.Init.Options.noInit then
      // do nothing
    elseif initOpt == Choices.Init.Options.fixedState then
      if not noInitialPressure then
        p = pstart;
      end if;
      Vl = Vlstart;
    elseif initOpt == Choices.Init.Options.steadyState then
      if not noInitialPressure then
        der(p) = 0;
      end if;
      der(Vl) = 0;
    else
      assert(false, "Unsupported initialisation option");
    end if;
    annotation (
      Diagram(graphics),
      Documentation(info="<HTML>
<p>Simplified model of a drum for drum boilers and fire-tube boilers. This model assumes
<ul>
<li>Thermodynamic equiibrium between the liquid, vapour, and metal wall
<li>Perfect separation of the liquid and vapour phase
</ul></p>
<p>The model has two state variables the pressure <code>p</code> and the liquid volume <code>Vl</code>. It is possible to extend it,
adding a specific geometry and the computation of the level from the liquid volume. In that case, one may want to use the level as a state.
</p>
</HTML>", revisions="<html>
<ul>
<li><i>19 Feb 2019</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Adapted from old <code>Drum2States</code> model.</li>
</ul>
</html>"),
      Icon(graphics));
  end DrumEquilibrium;

  model ValveLin "Valve for water/steam flows with linear pressure drop"
    extends Icons.Water.Valve;
    replaceable package Medium = StandardWater constrainedby
      Modelica.Media.Interfaces.PartialMedium "Medium model"
      annotation(choicesAllMatching = true);
    parameter Units.HydraulicConductance Kv "Nominal hydraulic conductance";
    parameter Boolean allowFlowReversal=system.allowFlowReversal
      "= true to allow flow reversal, false restricts to design direction"
      annotation(Evaluate=true);
    outer ThermoPower.System system "System wide properties";
    Medium.MassFlowRate w "Mass flowrate";
    FlangeA inlet(redeclare package Medium = Medium, m_flow(min=if
            allowFlowReversal then -Modelica.Constants.inf else 0)) annotation (
       Placement(transformation(extent={{-120,-20},{-80,20}}, rotation=0)));
    FlangeB outlet(redeclare package Medium = Medium, m_flow(max=if
            allowFlowReversal then +Modelica.Constants.inf else 0)) annotation (
       Placement(transformation(extent={{80,-20},{120,20}}, rotation=0)));
    Modelica.Blocks.Interfaces.RealInput cmd annotation (Placement(
          transformation(
          origin={0,80},
          extent={{-20,-20},{20,20}},
          rotation=270)));
  equation
    inlet.m_flow + outlet.m_flow = 0 "Mass balance";
    w = Kv*cmd*(inlet.p - outlet.p) "Valve characteristics";

    // Boundary conditions
    w = inlet.m_flow;
    inlet.h_outflow = inStream(outlet.h_outflow);
    inStream(inlet.h_outflow) = outlet.h_outflow;

    annotation (
      Icon(graphics={Text(extent={{-100,-40},{100,-74}}, textString="%name")}),
      Diagram(graphics),
      Documentation(info="<HTML>
<p>This very simple model provides a pressure drop which is proportional to the flowrate and to the <tt>cmd</tt> signal, without computing any fluid property.</p>
</HTML>", revisions="<html>
<ul>
<li><i>16 Dec 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Medium model and standard medium definition added.</li>
<li><i>1 Oct 2003</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       First release.</li>
</ul>
</html>"));
  end ValveLin;

  model ValveLiq "Valve for liquid water flow"
    extends BaseClasses.ValveBase;
    import ThermoPower.Choices.Valve.CvTypes;
  initial equation
    if CvData == CvTypes.OpPoint then
      wnom = FlowChar(thetanom)*Av*sqrt(rhonom)*sqrtR(dpnom)
        "Determination of Av by the operating point";
    end if;

  equation
    if CheckValve then
      w = homotopy(FlowChar(theta_act)*Av*sqrt(rho)*smooth(0, if dp >= 0 then sqrtR(
        dp) else 0), theta_act/thetanom*wnom/dpnom*(inlet.p - outlet.p));
    else
      w = homotopy(FlowChar(theta_act)*Av*sqrt(rho)*sqrtR(dp), theta_act/thetanom*wnom/
        dpnom*(inlet.p - outlet.p));
    end if;
    annotation (
      Icon(graphics={Text(extent={{-100,-40},{100,-80}}, textString="%name")}),
      Diagram(graphics),
      Documentation(info="<HTML>
<p>Liquid water valve model according to the IEC 534/ISA S.75 standards for valve sizing, incompressible fluid. <p>
Extends the <tt>ValveBase</tt> model (see the corresponding documentation for common valve features).
</html>", revisions="<html>
<ul>
<li><i>15 Mar 2005</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Rewritten with sqrtReg.</li>
<li><i>16 Dec 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Standard medium definition added.</li>
<li><i>1 Jul 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Valve model restructured using inheritance. <br>
       Adapted to Modelica.Media.</li>
<li><i>1 Oct 2003</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       First release.</li>
</ul>
</HTML>"));
  end ValveLiq;

  model ValveVap "Valve for steam flow"
    extends BaseClasses.ValveBase;
    import ThermoPower.Choices.Valve.CvTypes;
    parameter Real Fxt_full=0.5 "Fk*xt critical ratio at full opening";
    replaceable function xtfun = Functions.ValveCharacteristics.one
      constrainedby Functions.ValveCharacteristics.baseFun
      "Critical ratio characteristic"
      annotation(choicesAllMatching = true);
    Real x "Pressure drop ratio";
    Real xs "Saturated pressure drop ratio";
    Real Y "Compressibility factor";
    Real Fxt "Fxt coefficient";
    Medium.AbsolutePressure p "Inlet pressure";
  protected
    parameter Real Fxt_nom(fixed=false) "Nominal Fxt";
    parameter Real x_nom(fixed=false) "Nominal pressure drop ratio";
    parameter Real xs_nom(fixed=false) "Nominal saturated pressure drop ratio";
    parameter Real Y_nom(fixed=false) "Nominal compressibility factor";
  initial equation
    if CvData == CvTypes.OpPoint then
      // Determination of Av by the nominal operating point conditions
      Fxt_nom = Fxt_full*xtfun(thetanom);
      x_nom = dpnom/pnom;
      xs_nom = smooth(0, if x_nom > Fxt_nom then Fxt_nom else x_nom);
      Y_nom = 1 - abs(xs_nom)/(3*Fxt_nom);
      wnom = FlowChar(thetanom)*Av*Y_nom*sqrt(rhonom)*sqrtR(pnom*xs_nom);
    else
      // Dummy values
      Fxt_nom = 0;
      x_nom = 0;
      xs_nom = 0;
      Y_nom = 0;
    end if;
  equation
    p = homotopy(if not allowFlowReversal then inlet.p else noEvent(if dp >= 0
       then inlet.p else outlet.p), inlet.p);
    Fxt = Fxt_full*xtfun(theta_act);
    x = dp/p;
    xs = smooth(0, if x < -Fxt then -Fxt else if x > Fxt then Fxt else x);
    Y = 1 - abs(xs)/(3*Fxt);
    if CheckValve then
      w = homotopy(FlowChar(theta_act)*Av*Y*sqrt(rho)*smooth(0, if xs >= 0 then
        sqrtR(p*xs) else 0), theta_act/thetanom*wnom/dpnom*(inlet.p - outlet.p));
    else
      w = homotopy(FlowChar(theta_act)*Av*Y*sqrt(rho)*sqrtR(p*xs), theta_act/thetanom*
        wnom/dpnom*(inlet.p - outlet.p));
    end if;
    annotation (
      Icon(graphics={Text(extent={{-100,-40},{100,-80}}, textString="%name")}),
      Diagram(graphics),
      Documentation(info="<HTML>
<p>Liquid water valve model according to the IEC 534/ISA S.75 standards for valve sizing, compressible fluid. <p>
Extends the <tt>ValveBase</tt> model (see the corresponding documentation for common valve features).
<p>The product Fk*xt is given by the parameter <tt>Fxt_full</tt>, and is assumed constant by default. The relative change (per unit) of the xt coefficient with the valve opening can be specified by customising the <tt>xtfun</tt> function.
</HTML>", revisions="<html>
<ul>
<li><i>15 Mar 2005</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Rewritten with sqrtReg.</li>
<li><i>16 Dec 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Standard medium definition added.</li>
<li><i>1 Jul 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Valve model restructured using inheritance. <br>
       Adapted to Modelica.Media.</li>
<li><i>1 Oct 2003</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       First release.</li>
</ul>
</HTML>"));
  end ValveVap;

  model ValveLiqChoked
    "Valve for liquid water flow, allows choked flow conditions"
    extends BaseClasses.ValveBase(redeclare replaceable package Medium =
          StandardWater constrainedby
        Modelica.Media.Interfaces.PartialTwoPhaseMedium);
    import ThermoPower.Choices.Valve.CvTypes;
    parameter Real Flnom=0.9 "Liquid pressure recovery factor";
    replaceable function Flfun = ThermoPower.Functions.ValveCharacteristics.one
      constrainedby Functions.ValveCharacteristics.baseFun
      "Pressure recovery characteristic";
    Medium.MassFlowRate w "Mass flowrate";
    SI.PerUnit Ff "Ff coefficient (see IEC/ISA standard)";
    SI.PerUnit Fl "Pressure recovery coefficient Fl (see IEC/ISA standard)";
    Medium.AbsolutePressure pv "Saturation pressure";
    SI.Pressure dpEff "Effective pressure drop";
  initial equation
    if CvData == CvTypes.OpPoint then
      wnom = FlowChar(thetanom)*Av*sqrt(rhonom)*sqrtR(dpnom)
        "Determination of Av by the operating point";
    end if;
  equation
    pv = Medium.saturationPressure(Tin);
    Ff = 0.96 - 0.28*sqrt(pv/Medium.fluidConstants[1].criticalPressure);
    Fl = Flnom*Flfun(theta_act);
    dpEff = if outlet.p < (1 - Fl^2)*inlet.p + Ff*Fl^2*pv then Fl^2*(inlet.p -
      Ff*pv) else inlet.p - outlet.p
      "Effective pressure drop, accounting for possible choked conditions";
    if CheckValve then
      w = homotopy(FlowChar(theta_act)*Av*sqrt(rho)*(if dpEff >= 0 then sqrtR(dpEff)
         else 0), theta_act/thetanom*wnom/dpnom*(inlet.p - outlet.p));
    else
      w = homotopy(FlowChar(theta_act)*Av*sqrt(rho)*sqrtR(dpEff), theta_act/thetanom*
        wnom/dpnom*(inlet.p - outlet.p));
    end if;
    annotation (
      Icon(graphics={Text(extent={{-100,-40},{100,-80}}, textString="%name")}),
      Diagram(graphics),
      Documentation(info="<HTML>
<p>Liquid water valve model according to the IEC 534/ISA S.75 standards for valve sizing, incompressible fluid, with possible choked flow conditions. <p>
Extends the <tt>ValveBase</tt> model (see the corresponding documentation for common valve features).<p>
The model operating range includes choked flow operation, which takes place for low outlet pressures due to flashing in the vena contracta; otherwise, non-choking conditions are assumed.
<p>The default liquid pressure recovery coefficient <tt>Fl</tt> is constant and given by the parameter <tt>Flnom</tt>. The relative change (per unit) of the recovery coefficient can be specified as a given function of the valve opening by customising the <tt>Flfun</tt> function.
<p>If the flow coefficient is specified in terms of a nominal operating point, this should be in non-chocked conditions.
</HTML>", revisions="<html>
<ul>
<li><i>15 Mar 2005</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Rewritten with sqrtReg.</li>
<<li><i>16 Dec 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Standard medium definition added.</li>
li><i>1 Jul 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Valve model restructured using inheritance. <br>
       Adapted to Modelica.Media.</li>
<li><i>1 Oct 2003</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       First release.</li>
</ul>
</HTML>"));
  end ValveLiqChoked;

  model Pump "Centrifugal pump with ideally controlled speed"
    extends BaseClasses.PumpBase;
    parameter NonSI.AngularVelocity_rpm n_const=n0 "Constant rotational speed"
      annotation(Dialog(enable = not use_in_n));
    Modelica.Blocks.Interfaces.RealInput in_n if use_in_n "RPM" annotation (Placement(
          transformation(
          origin={-26,80},
          extent={{-10,-10},{10,10}},
          rotation=270)));
    parameter Boolean use_in_n = false
      "Use connector input for the rotational speed"
      annotation(Dialog(group="External inputs"), choices(checkBox=true));
  protected
    Modelica.Blocks.Interfaces.RealInput in_n_int
      "Internal connector for rotational speed";
  equation
    connect(in_n, in_n_int);
    if not use_in_n then
      in_n_int = n_const "Rotational speed provided by parameter";
    end if;
    n = in_n_int "Rotational speed";
    annotation (
      Icon(graphics),
      Diagram(coordinateSystem(preserveAspectRatio=false, extent={{-100,-100},{
              100,100}}),
              graphics),
      Documentation(info="<HTML>
<p>This model describes a centrifugal pump (or a group of <tt>Np</tt> pumps in parallel) with controlled speed, either fixed or provided by an external signal.
<p>The model extends <tt>PumpBase</tt>
<p>If the <tt>in_n</tt> input connector is wired, it provides rotational speed of the pumps (rpm); otherwise, a constant rotational speed equal to <tt>n_const</tt> (which can be different from <tt>n0</tt>) is assumed.</p>
</HTML>", revisions="<html>
<ul>
<li><i>5 Jul 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Model restructured by using inheritance. Adapted to Modelica.Media.</li>
<li><i>15 Jan 2004</i>
    by <a href=\"mailto:francesco.schiavo@polimi.it\">Francesco Schiavo</a>:<br>
       <tt>ThermalCapacity</tt> and <tt>CheckValve</tt> added.</li>
<li><i>15 Dec 2003</i>
    by <a href=\"mailto:francesco.schiavo@polimi.it\">Francesco Schiavo</a>:<br>
       First release.</li>
</ul>
</html>"));
  end Pump;

  model PumpNPSH
    extends Pump(redeclare replaceable package Medium = StandardWater
        constrainedby Modelica.Media.Interfaces.PartialTwoPhaseMedium);
    SI.Height NPSHa "Net Positive Suction Head available";
    Medium.AbsolutePressure pv "Saturated liquid pressure";
  equation
    pv = Medium.saturationPressure(Tin);
    NPSHa = (infl.p - pv)/(rho*g);
    annotation (Documentation(info="<html>Same as Pump. Additionally, the net positive suction head available is computed. Requires a two-phase medium model to compute the saturation properties.
</html>", revisions="<html>
<ul>
<li><i>30 Jul 2007</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Added (removed NPSH from Pump model).</li>
</ul>
</html>"));
  end PumpNPSH;

  model PumpMech "Centrifugal pump with mechanical connector for the shaft"
    extends BaseClasses.PumpBase;
    extends Icons.Water.PumpMech;
    SI.Angle phi "Shaft angle";
    SI.AngularVelocity omega "Shaft angular velocity";
    Modelica.Mechanics.Rotational.Interfaces.Flange_a MechPort annotation (
        Placement(transformation(extent={{76,6},{106,36}}, rotation=0)));
  equation
    // Mechanical boundary condition
    phi = MechPort.phi;
    omega = der(phi);
    W = omega*MechPort.tau;

    n = SI.Conversions.to_rpm(omega) "Rotational speed";
    annotation (
      Icon(graphics={Text(extent={{-10,104},{18,84}}, textString="Np")}),
      Diagram(graphics),
      Documentation(info="<HTML>
<p>This model describes a centrifugal pump (or a group of <tt>Np</tt> pumps in parallel) with a mechanical rotational connector for the shaft, to be used when the pump drive has to be modelled explicitly. In the case of <tt>Np</tt> pumps in parallel, the mechanical connector is relative to a single pump.
<p>The model extends <tt>PumpBase</tt>
 </HTML>", revisions="<html>
<ul>
<li><i>5 Jul 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Model restructured by using inheritance. Adapted to Modelica.Media.</li>
<li><i>15 Jan 2004</i>
    by <a href=\"mailto:francesco.schiavo@polimi.it\">Francesco Schiavo</a>:<br>
       <tt>ThermalCapacity</tt> and <tt>CheckValve</tt> added.</li>
<li><i>15 Dec 2003</i>
    by <a href=\"mailto:francesco.schiavo@polimi.it\">Francesco Schiavo</a>:<br>
       First release.</li>
</ul>
</html>"));
  end PumpMech;

  model SprayCondenser
    "Model of a spray condenser  assuming  themodynamic equilibrium between the phases"
    replaceable package Medium = StandardWater constrainedby
      Modelica.Media.Interfaces.PartialTwoPhaseMedium "Medium model"
      annotation(choicesAllMatching = true);
    parameter SI.Volume Vt "Condenser total volume";
    parameter SI.Volume V0 "Volume of liquid at zero level";
    parameter SI.Height y0 "Height of liquid outlet over the zero level";
    parameter SI.Area A "Cross section";
                                          outer ThermoPower.System system "System wide properties";
    parameter SI.Pressure pstart "Pressure start value"
      annotation (Dialog(tab="Initialisation"));
    parameter SI.Height ystart "Start value of the level"
      annotation (Dialog(tab="Initialisation"));
    parameter Choices.Init.Options initOpt=system.initOpt
      "Initialisation option"
      annotation (Dialog(tab="Initialisation"));
    parameter Boolean noInitialPressure=false
      "Remove initial equation on pressure"
      annotation (Dialog(tab="Initialisation"),choices(checkBox=true));
    parameter Boolean noInitialLevel=false
      "Remove initial equation on level"
      annotation (Dialog(tab="Initialisation"),choices(checkBox=true));
    constant SI.Acceleration g = Modelica.Constants.g_n "Acceleration of gravity";

    Medium.SaturationProperties sat "Saturation conditions";
    FlangeA coolingWater(redeclare package Medium = Medium, m_flow(min=0)) annotation (
        Placement(transformation(extent={{-100,20},{-60,60}}, rotation=0),
          iconTransformation(extent={{-100,20},{-60,60}})));
    FlangeA condensingSteam(redeclare package Medium = Medium, m_flow(min=0)) annotation (
        Placement(transformation(extent={{-20,80},{20,120}}, rotation=0),
          iconTransformation(extent={{-20,80},{20,120}})));
    FlangeB liquidOutlet(redeclare package Medium = Medium) annotation (
        Placement(transformation(extent={{-20,-120},{20,-80}}, rotation=0),
          iconTransformation(extent={{-20,-120},{20,-80}})));
    SI.Mass Ml "Liquid water mass";
    SI.Mass Mv "Steam mass";
    SI.Mass M "Total liquid+steam mass";
    SI.Energy E "Total energy";
    SI.Volume Vl "Liquid water total volume";
    SI.Volume Vv "Steam volume";
    SI.Height y(start = ystart, stateSelect=StateSelect.prefer) "Level relative to zero reference";
    Medium.AbsolutePressure p(start=pstart,stateSelect=StateSelect.prefer)
      "Steam pressure";
    Medium.AbsolutePressure pl "Pressure at the liquid outlet";
    Medium.MassFlowRate qs "Condensing steam inlet mass flow rate";
    Medium.MassFlowRate qc "Cooling water  inlet mass flow rate";
    Medium.MassFlowRate ql "Saturated liquid outlet flow rate";
    Medium.SpecificEnthalpy hs "Condensing steam specific enthalpy";
    Medium.SpecificEnthalpy hc "Cooling water specific enthalpy";
    Medium.SpecificEnthalpy hl "Specific enthalpy of saturated liquid";
    Medium.SpecificEnthalpy hv "Specific enthalpy of saturated steam";
    Medium.Temperature Ts "Saturation temperature";
    Units.LiquidDensity rhol "Density of saturated liquid";
    Units.GasDensity rhov "Density of saturated steam";
  equation
    Ml = Vl*rhol "Mass of liquid";
    Mv = Vv*rhov "Mass of vapour";
    M = Ml + Mv "Total mass";
    E = Ml*hl + Mv*hv - p*Vt "Total energy";
    Vl = V0 + A*y "Volume - level relationship";
    Ts = Medium.saturationTemperature_sat(sat) "Saturation temperature";
    der(M) = qs + qc - ql "Mass balance";
    der(E) = qs*hs + qc*hc - ql*hl "Energy balance";
    Vt = Vl + Vv "Total volume";
    pl = p + rhol*g*(y + y0) "Static head between steam and liquid outlet";

    // Boundary conditions
    p =coolingWater.p;
    p =condensingSteam.p;
    pl = liquidOutlet.p;
    condensingSteam.m_flow = qs;
    coolingWater.m_flow = qc;
    -liquidOutlet.m_flow = ql;
    hs = inStream(condensingSteam.h_outflow);
    hc = inStream(coolingWater.h_outflow);
    condensingSteam.h_outflow = hv "Not used, no flow reversal";
    coolingWater.h_outflow = hl "Not used, no flow reversal";
    liquidOutlet.h_outflow = hl;

    // Fluid properties
    sat.psat = p;
    sat.Tsat = Medium.saturationTemperature(p);
    rhol = Medium.bubbleDensity(sat);
    rhov = Medium.dewDensity(sat);
    hl = Medium.bubbleEnthalpy(sat);
    hv = Medium.dewEnthalpy(sat);
  initial equation
    if initOpt == Choices.Init.Options.noInit then
      // do nothing
    elseif initOpt == Choices.Init.Options.fixedState then
      if not noInitialPressure then
        p = pstart;
      end if;
      if not noInitialLevel then
        y = ystart;
      end if;
    elseif initOpt == Choices.Init.Options.steadyState then
      if not noInitialPressure then
        der(p) = 0;
      end if;
      if not noInitialLevel then
        der(y) = 0;
      end if;
    else
      assert(false, "Unsupported initialisation option");
    end if;
    annotation (
      Documentation(info="<html>
<p>Model of a spray condenser. Thermodynamic equilibrium and perfect phase separation is assumed between the vapour and liquid phase, the condensate outlet pressure takes into account the static head due to the liquid level. The model assumes a cylindrical geometry with vertical axis in its validity range; by choosing Vt, V0, and y0 appropriately, any shape can be represented for the top and bottom of the vessel.  </p>
</html>", revisions="<html>
<ul>
<li><i>26 Jul 2017</i> <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>First release.</li>
</ul>
</html>"),   Icon(graphics={
          Rectangle(
            extent={{-60,60},{60,-60}},
            lineColor={0,0,255},
            pattern=LinePattern.None,
            fillColor={128,128,128},
            fillPattern=FillPattern.Solid),
          Ellipse(
            extent={{-60,80},{60,40}},
            lineColor={0,0,255},
            pattern=LinePattern.None,
            fillColor={128,128,128},
            fillPattern=FillPattern.Solid),
          Ellipse(
            extent={{-60,-40},{60,-80}},
            lineColor={0,0,255},
            pattern=LinePattern.None,
            fillColor={128,128,128},
            fillPattern=FillPattern.Solid),
          Ellipse(
            extent={{-52,74},{52,44}},
            lineColor={0,0,191},
            pattern=LinePattern.None,
            fillColor={159,159,223},
            fillPattern=FillPattern.Solid),
          Rectangle(
            extent={{-52,2},{52,-60}},
            lineColor={0,0,191},
            fillColor={0,0,191},
            fillPattern=FillPattern.Solid),
          Rectangle(
            extent={{-52,60},{52,0}},
            lineColor={0,0,255},
            pattern=LinePattern.None,
            fillColor={159,159,223},
            fillPattern=FillPattern.Solid),
          Ellipse(
            extent={{-52,-44},{52,-74}},
            lineColor={0,0,191},
            pattern=LinePattern.None,
            fillColor={0,0,191},
            fillPattern=FillPattern.Solid),
          Polygon(
            points={{-60,38},{2,38},{2,44},{-60,44},{-60,38}},
            lineColor={0,0,255},
            pattern=LinePattern.None,
            fillColor={128,128,128},
            fillPattern=FillPattern.Solid),
          Polygon(
            points={{2,38},{-10,26},{12,26},{2,38}},
            lineColor={0,0,255},
            fillColor={0,0,235},
            fillPattern=FillPattern.Solid)}));
  end SprayCondenser;

  model BarometricCondenser
    "Model of a barometric condenser including the barometric leg"
    replaceable package Medium = StandardWater constrainedby
      Modelica.Media.Interfaces.PartialTwoPhaseMedium "Medium model"
      annotation(choicesAllMatching = true);
    parameter SI.Time Tr = 1 "Residence time of the droplets in the condenser";
    parameter SI.MassFlowRate wnom "Nominal cooling water flow rate";
    parameter SI.TemperatureDifference Tt = 5 "Terminal temperature difference";
    parameter Boolean neglectLegDynamics = true "Neglect the dynamics of the barometric leg";

    parameter ThermoPower.Choices.Init.Options initOpt = system.initOpt "Initialization option"
       annotation (Dialog(tab="Initialisation"));
    parameter Medium.Temperature Tlstart = 293.15 "Liquid outlet temperature start value"
     annotation (Dialog(tab="Initialisation"));

    final parameter Medium.AbsolutePressure pstart = Medium.saturationPressure(Tlstart + Tt);
    final parameter Medium.SpecificEnthalpy hlstart = Medium.specificEnthalpy_pTX(pstart, Tlstart, fill(0,0));

    outer ThermoPower.System system "System wide properties";

    Medium.Temperature Tl "Liquid outlet temperature";
    Medium.SpecificEnthalpy hc "Cooling water specific enthalpy";
    Medium.SpecificEnthalpy hv "Condensing steam specific enthalpy";
    Medium.SpecificEnthalpy hl(start = hlstart, stateSelect = StateSelect.prefer)
      "Liquid outlet specific enthalpy";

    SI.MassFlowRate wc "Cooling water mass flow rate";
    SI.MassFlowRate wv "Condensing steam inlet mass flow rate";
    SI.MassFlowRate wl "Liquid outlet mass flow rate";

    FlangeA coolingWater(redeclare package Medium = Medium, m_flow(min=0)) "Cooling water inlet"
       annotation (Placement(transformation(extent={{-100,20},{-60,60}}, rotation=0),
          iconTransformation(extent={{-140,80},{-100,120}})));
    FlangeA condensingSteam(redeclare package Medium = Medium, m_flow(min=0)) "Condensing steam inlet"
       annotation (
        Placement(transformation(extent={{-20,80},{20,120}}, rotation=0),
          iconTransformation(extent={{-20,138},{20,178}})));
    FlangeB liquidOutlet(redeclare package Medium = Medium) "Liquid outlet" annotation (
        Placement(transformation(extent={{-20,-120},{20,-80}}, rotation=0),
          iconTransformation(extent={{-20,-172},{20,-132}})));

    Medium.AbsolutePressure p(start=pstart) "Steam pressure in the condenser";

  equation
    wc + wv = wl;
    Tr*wnom*der(hl) = wc*hc + wv*hv - wl*hl;
    Tl = Medium.temperature_ph(p, hl);
    p = Medium.saturationPressure(Tl + Tt);

    assert(neglectLegDynamics, "Full leg dynamics not implemented yet");

    // Boundary conditions
    p = coolingWater.p;
    p = condensingSteam.p;
    wc = coolingWater.m_flow;
    wv = condensingSteam.m_flow;
    wl = -liquidOutlet.m_flow;
    hv = inStream(condensingSteam.h_outflow);
    hc = inStream(coolingWater.h_outflow);
    condensingSteam.h_outflow = hv "Not used, no flow reversal";
    coolingWater.h_outflow = hl "Not used, no flow reversal";
    liquidOutlet.h_outflow = hl;

  initial equation
    if initOpt == ThermoPower.Choices.Init.Options.steadyState then
      der(hl) = 0;
    elseif initOpt == ThermoPower.Choices.Init.Options.fixedState then
      hl = hlstart;
    end if;

    annotation (
      Documentation(info="<html>
<p>Model of a barometric condenser including the barometric leg.</p>
<p>The incoming cooling water is sprayed in the condenser and mixes with the incoming steam flow. It is assumed that the residence time of the droplets in the condenser is equal to <code>Tr</code>. The pressure <code>p</code> in the condenser corresponds to the droplet temperature <code>Tl</code> plus the terminal temperature difference <code>Tt</code>, which is assumed to be constant for simplicity. </p>
<p>In most cases, barometric condensers discharge into tanks that have a much larger diameter and a much larger mass storage than the barometric leg. Therefore, the effects of the leg dynamics, i.e. the changes of the level in the pipe and the delay between the temperature at the condenser outlet and the temperature at the pipe outlet, are negligible. By setting <code>neglectLegDynamics = true</code>, the mass flow rate and specific enthalpy at the barometric leg outlet are assumed to be the same as the ones at the condenser outlet. </p>
<p>If <code>neglectLegDynamics</code> = false, the effects of mass, momentum and energy storage in the barometric leg are also accounted for. This is currently not yet implemented.</p>
</html>", revisions="<html>
<ul>
<li><i>26 Jul 2017</i> <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>First release.</li>
</ul>
</html>"),   Icon(coordinateSystem(extent={{-120,-160},{120,160}}),
                  graphics={
          Rectangle(
            extent={{-60,128},{60,58}},
            lineColor={0,0,255},
            pattern=LinePattern.None,
            fillColor={128,128,128},
            fillPattern=FillPattern.Solid),
          Ellipse(
            extent={{-60,140},{60,112}},
            lineColor={0,0,255},
            pattern=LinePattern.None,
            fillColor={128,128,128},
            fillPattern=FillPattern.Solid),
          Ellipse(
            extent={{-52,132},{54,116}},
            lineColor={0,0,191},
            pattern=LinePattern.None,
            fillColor={159,159,223},
            fillPattern=FillPattern.Solid),
          Rectangle(
            extent={{-54,124},{54,58}},
            lineColor={0,0,255},
            pattern=LinePattern.None,
            fillColor={159,159,223},
            fillPattern=FillPattern.Solid),
          Polygon(
            points={{-100,96},{2,96},{2,102},{-100,102},{-100,96}},
            lineColor={0,0,255},
            pattern=LinePattern.None,
            fillColor={128,128,128},
            fillPattern=FillPattern.Solid),
          Polygon(
            points={{0,96},{-12,84},{10,84},{0,96}},
            lineColor={0,0,255},
            fillColor={0,0,235},
            fillPattern=FillPattern.Solid),
          Polygon(
            points={{-54,60},{56,60},{12,2},{-10,2},{-54,60}},
            lineColor={159,159,223},
            fillColor={159,159,223},
            fillPattern=FillPattern.Solid),
          Polygon(
            points={{-60,60},{-12,0},{-4,-2},{-54,60},{-60,60}},
            lineColor={128,128,128},
            fillColor={128,128,128},
            fillPattern=FillPattern.Solid),
          Polygon(
            points={{54,60},{60,60},{12,2},{6,2},{54,60}},
            lineColor={128,128,128},
            fillColor={128,128,128},
            fillPattern=FillPattern.Solid),
          Rectangle(
            extent={{-12,2},{12,-140}},
            lineColor={0,0,255},
            pattern=LinePattern.None,
            fillColor={128,128,128},
            fillPattern=FillPattern.Solid),
          Rectangle(
            extent={{8,20},{-8,20}},
            fillColor={159,159,223},
            fillPattern=FillPattern.Solid,
            pattern=LinePattern.None),
          Rectangle(
            extent={{6,2},{-6,-136}},
            fillColor={0,0,255},
            fillPattern=FillPattern.Solid,
            pattern=LinePattern.None,
            lineColor={0,0,0})}),
      Diagram(coordinateSystem(extent={{-120,-160},{120,160}})));
  end BarometricCondenser;

  model CoolingTower "Cooling tower with variable speed fan"
    package Water = Modelica.Media.Water.StandardWater;
    package DryAir = Modelica.Media.Air.SimpleAir;

    outer ThermoPower.System system "System object";

    ThermoPower.Water.FlangeA waterInlet annotation (Placement(transformation(
            extent={{-10,80},{10,100}}), iconTransformation(extent={{-10,80},{10,100}})));
    ThermoPower.Water.FlangeB waterOutlet annotation (Placement(transformation(
            extent={{-10,-100},{10,-80}}), iconTransformation(extent={{-10,-100},{
              10,-80}})));
    Modelica.Blocks.Interfaces.RealInput fanRpm "Fan rotational speed in rpm"
      annotation (Placement(transformation(extent={{-100,60},{-60,100}}),
          iconTransformation(extent={{-90,30},{-70,50}})));

      Modelica.Blocks.Interfaces.RealOutput powerConsumption
      "Total fan power consumption"
      annotation (Placement(transformation(extent={{74,-10},{94,10}}),
          iconTransformation(extent={{70,-10},{90,10}})));
    Thermal.DHTVolumes tubeWalls(N = Nw, T = Tp, Q = Qwp*Nt) if closedCircuit
      "Interface to tube walls @ wall temperature"
      annotation (Placement(transformation(extent={{-80,-22},{-60,-2}}), iconTransformation(extent={{-90,-60}, {-70,0}})));

    parameter Boolean closedCircuit = false "true for closed-circuit tower";
    parameter Boolean staticModel = false "= true for a static model";
    parameter ThermoPower.Choices.Init.Options initOpt = system.initOpt "Initialization option"
       annotation (Dialog(tab="Initialisation", enable = not staticModel));
    parameter Integer Nt = 1 "Number of towers in parallel";
    parameter Integer N(min = 2) = 10 "Number of nodes";
    final parameter Integer Nw = N-1 "Number of volumes on the pipe wall";
    parameter SI.Mass M0 = 0
      "Water hold-up at zero water flow rate (single column)"
      annotation(Dialog(group = "Dynamic model only", enable = not staticModel));
    parameter SI.Mass Mnom = 0
      "Water hold-up at nominal water flow rate (single tower)"
      annotation(Dialog(group = "Dynamic model only", enable = not staticModel));
    parameter SI.MassFlowRate wlnom
      "Nominal water mass flow rate (single tower)";
    parameter SI.VolumeFlowRate qanom
      "Nominal air volume flow rate (single tower)";
    parameter SI.Density rhoanom "Nominal air density";
    parameter SI.Mass Mp = 0 "Mass of packing (single tower)"
      annotation(Dialog(group = "Dynamic model only",
                        enable = not staticModel and not closedCircuit));
    parameter SI.SpecificHeatCapacity cp = 0 "Specific heat of packing"
      annotation(Dialog(enable = not staticModel and not closedCircuit));
    parameter SI.Area S "Surface of air/water mass and heat transfer (single tower)";
    parameter SI.CoefficientOfHeatTransfer gamma_wp_nom = 0
      "Nominal heat transfer coefficient beween water and packing or tubes"
      annotation(Dialog(enable = not staticModel or closedCircuit));
    parameter Real k_wa_nom(final unit = "kg/(m2.s)")
      "Nominal total mass & heat transfer coefficient per unit surface (single tower)";
    parameter SI.PerUnit nu_a
      "Exponent of air flow rate in mass & heat transfer coefficients";
    parameter SI.PerUnit nu_l
      "Exponent of liquid flow rate in mass & heat transfer coefficients";
    parameter Real rpm_nom "Nominal fan rotational speed [rpm]";
    parameter SI.Power Wnom "Nominal power consumption (single tower)";
    parameter SI.Pressure patm = 101325 "Atmospheric pressure";
    parameter SI.Mass Mstart[N-1] = ones(N-1)*Mnom/(N-1) "Start value of water holdup in each volume"
       annotation (Dialog(tab="Initialisation", enable = not staticModel));
    parameter SI.SpecificEnthalpy hlstart[N] = fill(120e3,N) "Start values of liquid enthalpy at volume boundaries"
      annotation (Dialog(tab="Initialisation"));
    parameter SI.Temperature Tpstart[N-1] = ones(N-1)*(30+273.15) "Start value of packing temperature in each volume"
       annotation (Dialog(tab="Initialisation",
                          enable = not staticModel and not useHeatPort));
    parameter SI.Temperature Twbstart = system.T_wb "Start value of average wet bulb temperature"
      annotation (Dialog(tab="Initialisation"));
    final parameter SI.MassFlowRate wanom = qanom*rhoanom
      "Nominal air mass flow rate";

    constant Real MMv = 0.029;
    constant Real MMa = 0.018;

    SI.MassFlowRate wl[N] "Water flow rate";
    SI.MassFlowRate wa(start = qanom*rhoanom) "Dry air flow rate";
    SI.MassFlowRate wev[N-1] "Evaporation flow rate";
    SI.VolumeFlowRate qfan "Air volume flow rate through fan";
    Water.SpecificEnthalpy hl[N] "Water specific enthalpy";
    DryAir.SpecificEnthalpy ha[N]
      "Specific enthalpy of saturated humid air @ Twb, per unit dry mass";
    SI.SpecificEnthalpy hw[N]
      "Specific enthalpy of saturated humid air @ water temperature, per unit dry mass";
    Water.SpecificEnthalpy hvw[N]
      "Specific enthalpy of saturated steam at water temperature";
    Water.SpecificEnthalpy hva[N]
      "Specific enthalpy of saturated steam at interface (i.e. Twb)";
    DryAir.SpecificEnthalpy haw[N]
      "Dry air specific enthalpy @ liquid temperature";
    DryAir.SpecificEnthalpy haa[N]
      "Dry air specific enthalpy @ interface (i.e. Twb)";
    Water.AbsolutePressure pvw[N] "Saturation pressure at water temperature";
    Water.AbsolutePressure pva[N](each start = 5000, each nominal = 5000)
      "Saturation pressure at interface (i.e. Twb)";
    SI.MassFraction Xvw[N](each start = 0.01)
      "Absolute humidity (Mv/Ma_dry) of saturated air at the liquid temperature";
    SI.MassFraction Xva[N](each start = 0.01)
      "Absolute humidity (Mv/Ma_dry) of air at the interface";
    Water.Temperature Tl[N](each start = 300) "Water temperature at the nodes";
    Water.Temperature Tla[N-1](each start = 300) "Average water temperature for each volume";
    Water.Temperature Twb[N](each start = Twbstart)
      "Wet bulb temperature of air at interface";
    SI.Mass M[N-1](
      each start = Mnom/(N-1),
      each stateSelect = if staticModel then StateSelect.default else StateSelect.prefer)
       "Water hold-up";
    Water.SpecificEnthalpy hltilde[N-1](
      start = hlstart[2:N],
      each stateSelect = if staticModel then StateSelect.default else StateSelect.prefer)
      "Specific enthalpy state variable";
    SI.Temperature Tp[N-1](
      start = Tpstart,
      each stateSelect = if not staticModel and not closedCircuit then StateSelect.prefer else StateSelect.default)
       "Temperature of packing or tube surface";
    SI.Power Qwp[N-1] "Thermal power transfer between water and packing or tubes";
    SI.Power Q[N-1] "Total thermal power transfer water -> air interface (@Twb)";
    SI.Power W "Power consumption of the fan (single column)";
    SI.Power Wtot "Power consumption of the fans (all columns)";
    SI.CoefficientOfHeatTransfer gamma_wp[N](each start = gamma_wp_nom)
      "Heat transfer coefficient between water and packing or tubes";
    Real k_wa(final unit = "kg/(m2.s)", start = k_wa_nom)
      "Total evaporation heat transfer coefficient per unit surface";

    SI.Temperature Tlin "Inlet water temperature";
    SI.Temperature Tlout "Outlet water temperature";

  equation
    for i in 1:N-1 loop
      // Liquid mass and energy balance
      if staticModel then
        0 = wl[i] - wl[i+1] - wev[i];
        0 = wl[i]*hl[i] - wl[i+1]*hl[i+1] - Q[i] + Qwp[i];
        M[i] = 0;
      else
        der(M[i]) = wl[i] - wl[i+1] - wev[i];
        der(M[i])*hltilde[i] + M[i]*der(hltilde[i]) =
          wl[i]*hl[i] - wl[i+1]*hl[i+1] - Q[i] + Qwp[i];
        wl[i+1] = (M[i] - M0/(N-1))/(Mnom/(N-1) - M0/(N-1))*wlnom;
      end if;

      // Energy balance for packing/tubes
      // if closedCircuit = true, Qwp is bound to the tubeWalls.Q variable in the connector
      if not closedCircuit then
        if not Mp > 0 or staticModel then
           0 = -Qwp[i];
        else
           cp*Mp/(N-1)*der(Tp[i]) = -Qwp[i];
        end if;
      end if;


      // Equation for Qwp for open-circuit dynamic model with packing
      // and for closed-circuit model with external tubes
      // otherwise dummy equation for unused Tp
      if closedCircuit or (not staticModel and Mp > 0) then
        Qwp[i] = (Tp[i] - Tla[i])*S/(N-1)*gamma_wp[i];
      else
        Tp[i] = Tl[i];
      end if;

      wa*Xva[i+1] + wev[i] = wa*Xva[i] "vapour mass balance in air";
      wa*ha[i+1] + Q[i] = wa*ha[i] "energy balance @ air interface";

      hltilde[i] = hl[i+1];

      Q[i] = ((hw[i] + hw[i+1])/2 - (ha[i] + ha[i+1])/2)*S/(N-1)*k_wa;

      Tla[i] = if closedCircuit then Tl[i+1] else (Tl[i] + Tl[i+1])/2;
    end for;

    for i in 1:N loop
      Tl[i] = Water.temperature_ph(patm, hl[i]);
      pvw[i] = Water.saturationPressure(Tl[i]);
      pva[i] = Water.saturationPressure(Twb[i]);
      hvw[i] = Water.dewEnthalpy(Water.setSat_T(Tl[i]));
      hva[i] = Water.dewEnthalpy(Water.setSat_T(Twb[i]));
      haw[i] = DryAir.specificEnthalpy(DryAir.setState_pTX(patm, Tl[i]));
      haa[i] = DryAir.specificEnthalpy(DryAir.setState_pTX(patm, Twb[i]));
      pvw[i]/patm = Xvw[i]*MMa/(Xvw[i]*MMa+MMv)
        "Saturation conditions @ liquid temperature";
      pva[i]/patm = Xva[i]*MMa/(Xva[i]*MMa+MMv)
        "Saturation conditions @ interface (i.e. Twb)";
      hw[i] = haw[i] + hvw[i]*Xvw[i];
      ha[i] = haa[i] + hva[i]*Xva[i];

      gamma_wp[i] = gamma_wp_nom*max(wl[i]/wlnom, 0.3)^nu_l;
    end for;

    k_wa = k_wa_nom*max(wa/wanom, 0.3)^nu_a*max(wl[1]/wlnom, 0.3)^nu_l;
    qfan = qanom*fanRpm/rpm_nom;
    wa = qfan*rhoanom "Dry air flow roughly equal to humid air flow (+/- 1%)";
    W = Wnom*(fanRpm/rpm_nom)^3;
    Wtot = W*Nt;

    // Boundary conditions
    wl[1] = waterInlet.m_flow/Nt;
    wl[N] = -waterOutlet.m_flow/Nt;
    waterInlet.p = patm;
    hl[1] = inStream(waterInlet.h_outflow);
    waterInlet.h_outflow = hltilde[1];
    waterOutlet.h_outflow = hl[N];
    Twb[N] = system.T_wb;

    powerConsumption = Wtot;

    // Monitoring variables
    Tlin = Tl[1];
    Tlout = Tl[N];

  initial equation
    if not staticModel and initOpt == ThermoPower.Choices.Init.Options.steadyState then
      der(M) = zeros(N-1);
      der(hltilde) = zeros(N-1);
      if Mp > 0 then
        der(Tp) = zeros(N-1);
      end if;
    elseif not staticModel and initOpt == ThermoPower.Choices.Init.Options.fixedState then
      M = Mstart;
      hltilde = hlstart[2:N];
      if Mp > 0 then
        Tp = Tpstart;
      end if;
    end if;

    // Default parameter values not allowed for dynamic model
    if closedCircuit then
      assert(not Mp > 0, "A closed-circuit tower should have Mp = 0");
    end if;
    if not staticModel then
      assert(M0 > 0, "M0 must be positive");
      assert(Mnom > 0, "Mnom must be positive");
      assert(not (Mp > 0 and not cp > 0), "If Mp > 0 then cp must be positive");
      assert(not (Mp > 0 and not gamma_wp_nom > 0), "If Mp > 0 then gamma_wp_nom must be positive");
    end if;
    annotation (Icon(graphics={Polygon(
            points={{-70,80},{-70,-80},{70,-80},{70,80},{-70,80}},
            lineColor={0,0,0},
            smooth=Smooth.None,
            fillColor={0,0,255},
            fillPattern=FillPattern.Solid), Polygon(
            points={{-12,36},{-28,36},{-40,48},{-28,62},{-12,62},{12,36},{30,36},
                {40,48},{30,62},{12,62},{0,48},{-12,36}},
            lineColor={0,0,0},
            smooth=Smooth.None,
            fillColor={255,255,255},
            fillPattern=FillPattern.Solid)}), Documentation(info="<html>
<p>This model represents a cooling tower with variable speed fans. If <code>closedCircuit</code> is false, the model
represents a cooling tower filled with metallic packing, where the incoming water is cooled by direct contact with humid air,
by means of evaporation. Dynamic models with <code>Mp > 0</code> also represent heat storage in the packing and heat
transfer between the packing and the evaporating water.</p>
<p>If <code>closedCircuit</code> is true and <code>Mp = 0</code>, then the model represents a closed-circuit tower cooling an
external circuit, which is thermally connected through the 1D distributed heat port <code>wallPort</code>, representing the tube external surface.</p>
<p>The heat transfer between the packing or the tube surface and the evaporating water is computed by a specific
heat transfer coefficient, whose nominal value is <code>gamma_wp_nom</code>, and which varies with the <code>nu_l</code>-th power
of the liquid flow.</p>  
<p>The mass and heat transfer from the hot water to humid ambient air is modelled according to Merkel&apos;s equation: the driving force for heat and mass transfer is the difference between the specific enthalpy of saturated humid air at the water temperature per unit dry air mass, and the specific enthalpy of saturated humid air at the wet bulb temperature Twb per unit dry air mass.
The dry and wet bulb temperatures of incoming air are given by the settings of the system object.</p>
<p>The 1D counter-current heat and mass transfer equations are discretized by the finite volume method, with <code>N-1</code> volumes; average quantities between volume inlet and volume outlet are used to compute the driving force of the mass and energy transfer.</p>
<p>Humid air is modelled as an ideal mixture of dry air and steam, using the IF97 water-steam model.</p>
<p>The hold-up of water in the packaging is modelled assuming a simple linear relationship between the hold-up in each volume and the corresponding outgoing flow, which is calibrated by the <code>Mnom</code> and <code>M0</code> parameters. The energy storage in the water hold-up and in the packaging is accounted for.</p>
<p>The behaviour of the fan is modelled by kinematic similarity; the air flow is proportional to the fan rpm, while the consumption is proportional to the cube of the fan rpm.</p>
<p>Is it possible to neglect all dynamic behaviour and get a static model by setting <code>staticModel=true</code>.</p>
</html>",   revisions="<html>
<ul>
<li><i>28 Jul 2017</i> <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>First release.</li>
</ul>
</html>"));
  end CoolingTower;

  model ExpansionTankIdeal "Ideal expansion tank with prescribed pressure"
    extends Icons.Water.ExpansionTankIdeal;
    replaceable package Medium = Modelica.Media.Water.StandardWater constrainedby
      Modelica.Media.Interfaces.PartialMedium  "Liquid medium model" annotation (
       choicesAllMatching = true);
    outer ThermoPower.System system "System wide properties";
    parameter Boolean allowFlowReversal = system.allowFlowReversal "= true to allow flow reversal, false restricts to design direction" annotation (
      Evaluate = true);
    parameter SI.Pressure pf "Fixed flange pressure";
    Medium.MassFlowRate wn "Net entering mass flow rate";

    ThermoPower.Water.FlangeA WaterInfl(redeclare package Medium = Medium, m_flow(min = if allowFlowReversal then -Modelica.Constants.inf else 0)) annotation (
      Placement(transformation(extent={{-60,-80},{-20,-40}},       rotation = 0),
          iconTransformation(extent={{-60,-80},{-20,-40}})));
    ThermoPower.Water.FlangeB WaterOutfl(redeclare package Medium = Medium, m_flow(max = if allowFlowReversal then +Modelica.Constants.inf else 0)) annotation (
      Placement(transformation(extent={{20,-80},{60,-40}},       rotation = 0),
          iconTransformation(extent={{20,-80},{60,-40}})));

  equation
    WaterInfl.h_outflow = inStream(WaterOutfl.h_outflow);
    WaterOutfl.h_outflow = inStream(WaterInfl.h_outflow);
    WaterInfl.p = pf;
    WaterOutfl.p = pf;
    wn = WaterInfl.m_flow + WaterOutfl.m_flow;
    annotation (Icon(coordinateSystem(preserveAspectRatio=false)), Diagram(
          coordinateSystem(preserveAspectRatio=false)),
      Documentation(info="<html>
<p>This model implements an ideal expansion tank, in wich the pressure at the bottom flanges is prescribed, while the water mass is free to change in order to compensaste the fluid expansion in the circuit connected to the expansion tank itself.</p>
<p>Water flows in and out through the interfaces at the expansion tank bottom (flow reversal supported), the water entalpy is transferred through the flanges following to the water flow direction, whithout changes.</p>
<h4>Parameters</h4>
<ul>
<li>pf: prescribed pressure at the bottom flanges.</li>
</ul>
</html>", revisions="<html>
<ul>
<li><i>12 Dec 2018</i> <a href=\"mailto:andrea.bartolini@dynamica-it.com\">Andrea Bartolini</a>:<br>First release.</li>
</ul>
<p>First Release.</p>
</html>"));
  end ExpansionTankIdeal;

  function f_chen "Chen's correlation for two-phase flow in a tube"

    input SI.MassFlowRate w "Mass flowrate";
    input SI.Length D "Tube hydraulic diameter";
    input SI.Area A "Tube cross-section";
    input SI.DynamicViscosity muf "Liquid dynamic viscosity";
    input SI.ThermalConductivity kf "Liquid thermal conductivity";
    input SI.SpecificHeatCapacity cpf "Liquid cp";
    input SI.Density rhof "Liquid density";
    input SI.SurfaceTension sigma "Surface Tension";
    input SI.Density rhog "Vapour density";
    input SI.DynamicViscosity mug "Vapour dynamic viscosity";
    input SI.Temperature DTsat "Saturation temperature difference (wall-bulk)";
    input SI.Pressure Dpsat "Saturation pressure difference (wall-bulk)";
    input SI.SpecificEnthalpy ifg "Latent heat of vaporization";
    input SI.PerUnit x "Steam quality";
    output SI.CoefficientOfHeatTransfer hTP
      "Two-phase total heat transfer coefficient";
  protected
    Real invXtt;
    Real F;
    Real S;
    Real Ref;
    Real Prf;
    Real ReTP;
    SI.CoefficientOfHeatTransfer hC;
    SI.CoefficientOfHeatTransfer hNcB;
  algorithm
    invXtt := (x/(1 - x))^0.9*(rhof/rhog)^0.5*(mug/muf)^0.1;
    if invXtt < 0.1 then
      F := 1;
    else
      F := 2.35*(invXtt + 0.213)^0.736;
    end if;
    Ref := (w/A*(1 - x)*D)/muf;
    Prf := (muf*cpf/kf);
    hC := 0.023*Ref^0.8*Prf^0.4*kf/D*F;
    ReTP := F^1.25*Ref;
    S := 1/(1 + 2.53e-6*ReTP^1.17);
    hNcB := 0.00122*(kf^0.79*cpf^0.45*rhof^0.49)/(sigma^0.5*muf^0.29*ifg^0.24*
      rhog^0.24)*max(0, DTsat)^0.24*max(0, Dpsat)^0.75*S;
    hTP := hC + hNcB;
    annotation (Documentation(info="<HTML>
<p>Chen's correlation for the computation of the heat transfer coefficient in two-phase flows.
<p><b>Revision history:</b></p>
<ul>
<li><i>20 Dec 2003</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       First release.</li>
</ul>
</HTML>"));
  end f_chen;

  function f_colebrook "Fanning friction factor for water/steam flows"
    input SI.MassFlowRate w;
    input Real D_A;
    input Real e;
    input SI.DynamicViscosity mu;
    output SI.PerUnit f;
  protected
    SI.PerUnit Re;
  algorithm
    Re := abs(w)*D_A/mu;
    Re := if Re > 2100 then Re else 2100;
    f := 0.332/(log(e/3.7 + 5.47/Re^0.9)^2);
    annotation (Documentation(info="<HTML>
<p>The Fanning friction factor is computed by Colebrook's equation, assuming turbulent, one-phase flow. For low Reynolds numbers, the limit value for turbulent flow is returned.
<p><b>Revision history:</b></p>
<ul>
<li><i>1 Oct 2003</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       First release.</li>
</ul>
</HTML>"));
  end f_colebrook;

  function f_colebrook_2ph
    "Fanning friction factor for a two phase water/steam flow"
    input SI.MassFlowRate w;
    input Real D_A;
    input Real e;
    input SI.DynamicViscosity mul;
    input SI.DynamicViscosity muv;
    input SI.PerUnit x;
    output SI.PerUnit f;
  protected
    SI.PerUnit Re;
  protected
    SI.DynamicViscosity mu;
  algorithm
    mu := 1/(x/muv + (1 - x)/mul);
    Re := w*D_A/mu;
    Re := if Re > 2100 then Re else 2100;
    f := 0.332/(log(e/3.7 + 5.47/Re^0.9)^2);
    annotation (Documentation(info="<HTML>
<p>The Fanning friction factor is computed by Colebrook's equation, assuming turbulent, homogeneous two-phase flow. For low Reynolds numbers, the limit value for turbulent flow is returned.
<p><b>Revision history:</b></p>
<ul>
<li><i>1 Oct 2003</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       First release.</li>
</ul>
</HTML>"));
  end f_colebrook_2ph;

  function f_dittus_boelter
    "Dittus-Boelter correlation for one-phase flow in a tube"

    input SI.MassFlowRate w;
    input SI.Length D;
    input SI.Area A;
    input SI.DynamicViscosity mu;
    input SI.ThermalConductivity k;
    input SI.SpecificHeatCapacity cp;
    output SI.CoefficientOfHeatTransfer hTC;
  protected
    SI.PerUnit Re;
    SI.PerUnit Pr;
  algorithm
    Re := abs(w)*D/A/mu;
    Pr := cp*mu/k;
    hTC := 0.023*k/D*Re^0.8*Pr^0.4;
    annotation (Documentation(info="<HTML>
<p>Dittus-Boelter's correlation for the computation of the heat transfer coefficient in one-phase flows.
<p><b>Revision history:</b></p>
<ul>
<li><i>20 Dec 2003</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
Input variables changed. This function now computes the heat transfer coefficient as a function of all the required fluid properties and flow parameters.</li>
<li><i>1 Oct 2003</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       First release.</li>
</ul>
</HTML>"));
  end f_dittus_boelter;

  model SteamTurbineStodola
    "Steam turbine: Stodola's ellipse law and constant isentropic efficiency"
    extends BaseClasses.SteamTurbineBase;
    parameter SI.PerUnit eta_iso_nom=0.92 "Nominal isentropic efficiency";
    parameter SI.Area Kt "Kt coefficient of Stodola's law";
    Medium.Density rho "Inlet density";
  equation
    rho =  Medium.density(steamState_in);
    w = homotopy(Kt*theta*sqrt(pin*rho)*Functions.sqrtReg(1 - (1/PR)^2),
                 theta*wnom/pnom*pin) "Stodola's law";
    eta_iso = eta_iso_nom "Constant efficiency";
    annotation (Documentation(info="<html>
<p>This model extends <tt>SteamTurbineBase</tt> by adding the actual performance characteristics:
<ul>
<li>Stodola's law
<li>Constant isentropic efficiency
</ul></p>
<p>The inlet flowrate is also proportional to the <tt>partialArc</tt> signal if the corresponding connector is wired. In this case, it is assumed that the flow rate is reduced by partial arc admission, not by throttling (i.e., no loss of thermodynamic efficiency occurs). To simulate throttling, insert a valve model before the turbine inlet.
</html>", revisions="<html>
<ul>
<li><i>20 Apr 2005</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       First release.</li>
</ul>
</html>"));
  end SteamTurbineStodola;

  model SteamTurbineUnit "Simplified HP+LP turbine unit for steam flows"
    replaceable package Medium = StandardWater constrainedby
      Modelica.Media.Interfaces.PartialMedium "Medium model"
      annotation(choicesAllMatching = true);
    extends Icons.Water.SteamTurbineUnit;
    parameter Medium.AbsolutePressure pnom "Inlet nominal pressure";
    parameter Medium.MassFlowRate wnom "Inlet nominal flow rate";
    parameter SI.PerUnit eta_iso "Isentropic efficiency [PerUnit]";
    parameter SI.PerUnit eta_mech=0.98 "Mechanical efficiency [PerUnit]";
    parameter SI.PerUnit hpFraction
      "Fraction of power provided by the HP turbine [PerUnit]";
    parameter SI.Time T_HP "Time constant of HP mechanical power response";
    parameter SI.Time T_LP "Time constant of LP mechanical power response";
    parameter Boolean allowFlowReversal=system.allowFlowReversal
      "= true to allow flow reversal, false restricts to design direction"
      annotation(Evaluate=true);
    outer ThermoPower.System system "System wide properties";
    parameter SI.MassFlowRate wstart = wnom "Flow rate start value"
        annotation (Dialog(tab="Initialization"));
    parameter Medium.AbsolutePressure pstartin=pnom "Inlet start pressure"
      annotation (Dialog(tab="Initialization"));
    parameter Medium.SpecificEnthalpy hstartin "Inlet enthalpy start value"
      annotation (Dialog(tab="Initialization"));
    parameter Medium.SpecificEnthalpy hstartout "Outlet enthalpy start value"
      annotation (Dialog(tab="Initialization"));
    parameter SI.Power P_HPstart = wstart*(hstartin - hstartout)*hpFraction
      "HP turbine power start value"
        annotation (Dialog(tab="Initialization"));
    parameter SI.Power P_LPstart = wstart*(hstartin - hstartout)*(1-hpFraction)
      "LP turbine power start value"
        annotation (Dialog(tab="Initialization"));
    parameter ThermoPower.Choices.Init.Options initOpt=system.initOpt
      "Initialization option" annotation (Dialog(tab="Initialization"));
    Medium.ThermodynamicState fluidState_in(p(start=pstartin),h(start=hstartin));
    FlangeA inlet(redeclare package Medium = Medium, m_flow(min=if
            allowFlowReversal then -Modelica.Constants.inf else 0)) annotation (
       Placement(transformation(extent={{-120,50},{-80,90}}, rotation=0)));
    FlangeB outlet(redeclare package Medium = Medium, m_flow(max=if
            allowFlowReversal then +Modelica.Constants.inf else 0)) annotation (
       Placement(transformation(extent={{80,-90},{120,-50}}, rotation=0)));
    Modelica.Mechanics.Rotational.Interfaces.Flange_a shaft_a annotation (
        Placement(transformation(extent={{-110,-14},{-84,14}}, rotation=0)));
    Modelica.Mechanics.Rotational.Interfaces.Flange_b shaft_b annotation (
        Placement(transformation(extent={{86,-14},{112,14}}, rotation=0)));
    Medium.MassFlowRate w "Mass flowrate";
    SI.Angle phi "Shaft rotation angle";
    SI.AngularVelocity omega "Shaft angular velocity";
    SI.Torque tau "Net torque acting on the turbine";
    Real Kv(unit="kg/(s.Pa)") "Turbine nominal admittance at full throttle";
    Medium.SpecificEnthalpy hin(start=hstartin) "Inlet enthalpy";
    Medium.SpecificEnthalpy hout(start=hstartout) "Outlet enthalpy";
    Medium.SpecificEnthalpy hiso(start=hstartout) "Isentropic outlet enthalpy";
    SI.Power Pm "Mechanical power input";
    SI.Power P_HP(start = P_HPstart)
      "Mechanical power produced by the HP turbine";
    SI.Power P_LP(start = P_LPstart)
      "Mechanical power produced by the LP turbine";
    Modelica.Blocks.Interfaces.RealInput partialArc annotation (Placement(
          transformation(extent={{-110,-88},{-74,-52}}, rotation=0)));
  equation
    if cardinality(partialArc) == 0 then
      partialArc = 1 "Default value if not connected";
    end if;
    Kv = partialArc*wnom/pnom "Definition of Kv coefficient";
    w = Kv*inlet.p "Flow characteristics";
    hiso = Medium.isentropicEnthalpy(outlet.p, fluidState_in)
      "Isentropic enthalpy";
    hin - hout = eta_iso*(hin - hiso) "Computation of outlet enthalpy";
    Pm = eta_mech*w*(hin - hout) "Mechanical power from the fluid";
    T_HP*der(P_HP) = Pm*hpFraction - P_HP "Power output to HP turbine";
    T_LP*der(P_LP) = Pm*(1 - hpFraction) - P_LP "Power output to LP turbine";
    P_HP + P_LP = -tau*omega "Mechanical power balance";

    // Mechanical boundary conditions
    shaft_a.phi = phi;
    shaft_b.phi = phi;
    shaft_a.tau + shaft_b.tau = tau;
    der(phi) = omega;

    // Fluid boundary conditions and inlet fluid properties
    fluidState_in = Medium.setState_phX(inlet.p, hin);
    hin = inStream(inlet.h_outflow);
    hout = outlet.h_outflow;
    w = inlet.m_flow;

    inlet.m_flow + outlet.m_flow = 0 "Mass balance";
    assert(w >= 0, "The turbine model does not support flow reversal");

    // The next equation is provided to close the balance but never actually used
    inlet.h_outflow = outlet.h_outflow;
  initial equation
    if initOpt == ThermoPower.Choices.Init.Options.noInit then
      // do nothing
    elseif initOpt == ThermoPower.Choices.Init.Options.fixedState then
      P_HP = P_HPstart;
      P_LP = P_LPstart;
    elseif initOpt == ThermoPower.Choices.Init.Options.steadyState then
      der(P_HP) = 0;
      der(P_LP) = 0;
    else
      assert(false, "Unsupported initialisation option");
    end if;

    annotation (
      Icon(graphics={Text(extent={{-108,-80},{108,-110}}, textString="%name"),
            Line(
            points={{-74,-70},{-74,-70},{-56,-70},{-56,-30}},
            color={0,0,0},
            thickness=0.5)}),
      Documentation(info="<HTML>
<p>This model describes a simplified steam turbine unit, with a high pressure and a low pressure turbine.<p>
The inlet flowrate is proportional to the inlet pressure, and to the <tt>partialArc</tt> signal if the corresponding connector is wired. In this case, it is assumed that the flow rate is reduced by partial arc admission, not by throttling (i.e., no loss of thermodynamic efficiency occurs). To simulate throttling, insert a valve before the turbine unit inlet.
<p>The model assumes that a fraction <tt>hpFraction</tt> of the available hydraulic power is converted by the HP turbine with a time constant of <tt>T_HP</tt>, while the remaining part is converted by the LP turbine with a time constant of <tt>L_HP</tt>.
<p>This model does not include any shaft inertia by itself; if that is needed, connect a <tt>Modelica.Mechanics.Rotational.Inertia</tt> model to one of the shaft connectors.
<p>The model requires the <tt>Modelica.Media</tt> library (<tt>ThermoFluid</tt> does not compute the isentropic enthalpy correctly).
</HTML>", revisions="<html>
<ul>
<li><i>16 Dec 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Standard medium definition added.</li>
<li><i>4 Aug 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       First release.</li>
</ul>
</html>"),
      Diagram(graphics));
  end SteamTurbineUnit;

  package Utility "Utility models"

    model ClosedSystemInit
      "Component for the steady-state initialization of closed systems"
      replaceable package Medium = StandardWater constrainedby
        Modelica.Media.Interfaces.PartialMedium "Medium model"
        annotation(choicesAllMatching = true);
      parameter Medium.AbsolutePressure pstart "Start value of pressure";
      parameter Boolean initEquationFromInput = false
        "Get initial condition residual from input connector"
        annotation(Dialog(group="External inputs"), choices(checkBox=true));
      parameter Boolean useHomotopy
        "Use homotopy for residual-based initialization";
      final parameter Medium.MassFlowRate w_b(fixed = false, start = 0)
        "Initial balance flow rate eventually equal to zero";
      outer ThermoPower.System system "System wide properties";

      FlangeB flange(redeclare package Medium = Medium, m_flow(min = 0))
         annotation (Placement(transformation(extent={{-20,-100},{20,-60}},
                               rotation=0),
                               iconTransformation(extent={{-20,-100},{20,-60}})));
      Modelica.Blocks.Interfaces.RealInput initEquationResidual if initEquationFromInput
        "Residual of initial equation" annotation (Placement(transformation(extent={
                {-60,0},{-20,40}}), iconTransformation(extent={{-60,-10},{-40,10}})));
    protected
      Modelica.Blocks.Interfaces.RealInput initEquationResidual_int
        "Hidden internal connector for conditional connection";
    equation
      0 = flange.m_flow + w_b "Mass balance";
      flange.h_outflow = Medium.h_default
        "Unused value as there is no flow out of the flange";

      connect(initEquationResidual, initEquationResidual_int)
        "Connects conditional input to hidden connector";

      if not initEquationFromInput then
        initEquationResidual_int = 0 "Not used";
      end if;

    initial equation
      if initEquationFromInput then
        if useHomotopy then
          homotopy(initEquationResidual_int, (flange.p - pstart)/pstart) = 0
            "Set initial value of residual to zero, simplified equation sets start value of pressure";
        else
          initEquationResidual_int = 0 "Set initial value of residual to zero";
        end if;
      else
        flange.p = pstart "Set initial value of pressure";
      end if;

      annotation (Icon(coordinateSystem(preserveAspectRatio=false), graphics={
            Line(
              points={{0,0},{0,-60}},
              color={28,108,200},
              thickness=0.5),
            Ellipse(
              extent={{-40,40},{40,-40}},
              lineColor={28,108,200},
              fillColor={0,0,255},
              fillPattern=FillPattern.Solid),
            Text(
              extent={{-32,24},{30,-24}},
              lineColor={255,255,255},
              lineThickness=0.5,
              fillColor={0,0,255},
              fillPattern=FillPattern.Solid,
              textString="Init")}),                                  Diagram(
            coordinateSystem(preserveAspectRatio=false)),
        Documentation(info="<html>
<p>This component can be used for the steady-state initialization of closed-system where all components have steady-state initial conditions. Without this component such systems would give rise to undetermined initial conditions, i.e., the amount of fluid and the initial pressures in the system would be unspecified.</p>
<p>Connect the component to one point of the system. If <code>initEquationFromInput = false</code>, the system is initialized with pressure equal to <code>pstart</code> at the connection point.</p>
<p>It is possible to use a generic initial equation instead of <code>p = pstart</code>, e.g., to set the initial charge of a refrigeration circuit, by setting <code>initEquationFromInput = true</code> and connecting to the input the output of a <a href=\"Modelica://Modelica.Blocks.Sources.RealExpression\">Modelica.Blocks.Sources.RealExpression</a> component, containing the residual of the initial equation. In this case, if <code>useHomotopy = true</code>, the simplified initial equation is <code>(p - pstart)/pstart = 0</code>. To ensure a smooth homotopy transformation, it is recommended to write the residual in normalized form, i.e., with values have the order of magnitude of one, as for the simplified equation.</p>
</html>"));
    end ClosedSystemInit;
  end Utility;

  package BaseClasses "Contains partial models"
    extends Modelica.Icons.BasesPackage;
    partial model Flow1DBase
      "Basic interface for 1-dimensional water/steam fluid flow models"
      import ThermoPower.Choices.Flow1D.FFtypes;
      replaceable package Medium = StandardWater constrainedby
        Modelica.Media.Interfaces.PartialMedium "Medium model"
        annotation(choicesAllMatching = true);
      extends Icons.Water.Tube;
      constant Real pi = Modelica.Constants.pi;
      parameter Integer N(min=2) = 2 "Number of nodes for thermal variables";
      parameter Integer Nw = N - 1 "Number of volumes on the wall interface";
      parameter Integer Nt = 1 "Number of tubes in parallel";
      parameter SI.Distance L "Tube length" annotation (Evaluate=true);
      parameter SI.Position H=0 "Elevation of outlet over inlet";
      parameter SI.Area A "Cross-sectional area (single tube)";
      parameter SI.Length omega
        "Perimeter of heat transfer surface (single tube)";
      parameter SI.Length Dhyd = omega/pi "Hydraulic Diameter (single tube)";
      parameter Medium.MassFlowRate wnom "Nominal mass flowrate (total)";
      parameter ThermoPower.Choices.Flow1D.FFtypes FFtype=ThermoPower.Choices.Flow1D.FFtypes.NoFriction
        "Friction Factor Type"
        annotation (Evaluate=true);
      parameter SI.PressureDifference dpnom = 0
        "Nominal pressure drop (friction term only!)";
      parameter Real Kfnom = 0
        "Nominal hydraulic resistance coefficient (DP = Kfnom*w^2/rho)"
       annotation(Dialog(enable = (FFtype == ThermoPower.Choices.Flow1D.FFtypes.Kfnom)));
      parameter Medium.Density rhonom=0 "Nominal inlet density"
        annotation(Dialog(enable = (FFtype == ThermoPower.Choices.Flow1D.FFtypes.OpPoint)));
      parameter SI.PerUnit Cfnom=0 "Nominal Fanning friction factor"
        annotation(Dialog(enable = (FFtype == ThermoPower.Choices.Flow1D.FFtypes.Cfnom)));
      parameter SI.PerUnit e=0 "Relative roughness (ratio roughness/diameter)"
        annotation(Dialog(enable = (FFtype == ThermoPower.Choices.Flow1D.FFtypes.Colebrook)));
      parameter SI.PerUnit Kfc=1 "Friction factor correction coefficient";
      parameter Boolean DynamicMomentum=false
        "Inertial phenomena accounted for"
        annotation (Evaluate=true);
      parameter ThermoPower.Choices.Flow1D.HCtypes HydraulicCapacitance=ThermoPower.Choices.Flow1D.HCtypes.Downstream
        "Location of the hydraulic capacitance";
      parameter Boolean avoidInletEnthalpyDerivative=true
        "Avoid inlet enthalpy derivative";
      parameter Boolean allowFlowReversal=system.allowFlowReversal
        "= true to allow flow reversal, false restricts to design direction"
      annotation(Evaluate=true);
      outer ThermoPower.System system "System wide properties";
      parameter Choices.FluidPhase.FluidPhases FluidPhaseStart=Choices.FluidPhase.FluidPhases.Liquid
        "Fluid phase (only for initialization!)"
        annotation (Dialog(tab="Initialisation"));
      parameter Medium.AbsolutePressure pstart=1e5 "Pressure start value"
        annotation (Dialog(tab="Initialisation"));
      parameter Medium.SpecificEnthalpy hstartin=if FluidPhaseStart == Choices.FluidPhase.FluidPhases.Liquid
           then 1e5 else if FluidPhaseStart == Choices.FluidPhase.FluidPhases.Steam
           then 3e6 else 1e6 "Inlet enthalpy start value"
        annotation (Dialog(tab="Initialisation"));
      parameter Medium.SpecificEnthalpy hstartout=if FluidPhaseStart == Choices.FluidPhase.FluidPhases.Liquid
           then 1e5 else if FluidPhaseStart == Choices.FluidPhase.FluidPhases.Steam
           then 3e6 else 1e6 "Outlet enthalpy start value"
        annotation (Dialog(tab="Initialisation"));
      parameter Medium.SpecificEnthalpy hstart[N]=linspace(
              hstartin,
              hstartout,
              N) "Start value of enthalpy vector (initialized by default)"
        annotation (Dialog(tab="Initialisation"));
      parameter SI.PerUnit wnf=0.02
        "Fraction of nominal flow rate at which linear friction equals turbulent friction";
      parameter Choices.Init.Options initOpt=system.initOpt
        "Initialisation option"
        annotation (Dialog(tab="Initialisation"));
      parameter Boolean noInitialPressure=false
        "Remove initial equation on pressure"
        annotation (Dialog(tab="Initialisation"),choices(checkBox=true));
      constant SI.Acceleration g=Modelica.Constants.g_n;
      function squareReg = ThermoPower.Functions.squareReg;

      FlangeA infl(
        h_outflow(start=hstartin),
        redeclare package Medium = Medium,
        m_flow(start=wnom, min=if allowFlowReversal then -Modelica.Constants.inf
               else 0)) annotation (Placement(transformation(extent={{-120,-20},
                {-80,20}}, rotation=0)));
      FlangeB outfl(
        h_outflow(start=hstartout),
        redeclare package Medium = Medium,
        m_flow(start=-wnom, max=if allowFlowReversal then +Modelica.Constants.inf
               else 0)) annotation (Placement(transformation(extent={{80,-20},{
                120,20}}, rotation=0)));
      SI.Power Q "Total heat flow through the lateral boundary (all Nt tubes)";
      SI.Time Tr "Residence time";
      final parameter SI.PerUnit dzdx=H/L "Slope" annotation (Evaluate=true);
      final parameter SI.Length l=L/(N - 1) "Length of a single volume";
      final parameter SI.Volume V = Nt*A*L "Total volume (all Nt tubes)";
    initial equation
        assert(wnom > 0, "Please set a positive value for wnom");
        assert(FFtype == FFtypes.NoFriction or dpnom > 0,
        "dpnom=0 not valid, it is also used in the homotopy trasformation during the inizialization");
        assert(not
                  (FFtype == FFtypes.Kfnom     and not Kfnom > 0),  "Kfnom = 0 not valid, please set a positive value");
        assert(not
                  (FFtype == FFtypes.OpPoint   and not rhonom > 0), "rhonom = 0 not valid, please set a positive value");
        assert(not
                  (FFtype == FFtypes.Cfnom     and not Cfnom > 0),  "Cfnom = 0 not valid, please set a positive value");
        assert(not
                  (FFtype == FFtypes.Colebrook and not Dhyd > 0),   "Dhyd = 0 not valid, please set a positive value");
        assert(not
                  (FFtype == FFtypes.Colebrook and not e > 0),      "e = 0 not valid, please set a positive value");
        annotation (Evaluate=true,
        Documentation(info="<HTML>
Basic interface of the <tt>Flow1D</tt> models, containing the common parameters and connectors.
</HTML>
",     revisions=
             "<html>
<ul>
<li><i>23 Jul 2007</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Added hstart for more detailed initialization of enthalpy vector.</li>
<li><i>30 May 2005</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Initialisation support added.</li>
<li><i>24 Mar 2005</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       <tt>FFtypes</tt> package and <tt>NoFriction</tt> option added.</li>
<li><i>16 Dec 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Standard medium definition added.</li>
<li><i>8 Oct 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Created.</li>
</ul>
</html>"),
        Diagram(graphics),
        Icon(graphics));
    end Flow1DBase;

    partial model ValveBase "Base model for valves"
      extends Icons.Water.Valve;
      replaceable package Medium = StandardWater constrainedby
        Modelica.Media.Interfaces.PartialMedium "Medium model"
        annotation(choicesAllMatching = true);
      Medium.ThermodynamicState fluidState;
      parameter ThermoPower.Choices.Valve.CvTypes CvData=ThermoPower.Choices.Valve.CvTypes.Av
        "Selection of flow coefficient"
       annotation (Dialog(group="Flow Coefficient"),
                   Evaluate = true);
      final parameter Boolean fixedAv=
        (if CvData == ThermoPower.Choices.Valve.CvTypes.Av then true else false)
        annotation(Evaluate = true);
      parameter SI.Area Av(
        fixed=fixedAv,
        start=wnom/(sqrt(rhonom*dpnom)*FlowChar(thetanom)))
        "Av (metric) flow coefficient"
        annotation (Dialog(group="Flow Coefficient",
                           enable=(CvData == ThermoPower.Choices.Valve.CvTypes.Av)));
      parameter Real Kv(unit="m3/h") = 0 "Kv (metric) flow coefficient"
        annotation (Dialog(group="Flow Coefficient",
                           enable=(CvData == ThermoPower.Choices.Valve.CvTypes.Kv)));
      parameter Real Cv=0 "Cv (US) flow coefficient [USG/min]"
        annotation (Dialog(group="Flow Coefficient",
                           enable=(CvData == ThermoPower.Choices.Valve.CvTypes.Cv)));
      parameter Boolean useThetaInput = true
        "Use the input connector for the valve opening"
        annotation(Dialog(group = "Valve Opening"), choices(checkBox = true));
      parameter SI.PerUnit theta_fix = 1
        "Fixed opening value when the input connector not used"
        annotation(Dialog(group= "Valve Opening", enable = not useThetaInput));
      parameter Medium.AbsolutePressure pnom "Nominal inlet pressure"
        annotation (Dialog(group="Nominal operating point"));
      parameter SI.PressureDifference dpnom "Nominal pressure drop"
        annotation (Dialog(group="Nominal operating point"));
      parameter Medium.MassFlowRate wnom "Nominal mass flowrate"
        annotation (Dialog(group="Nominal operating point"));
      parameter Medium.Density rhonom=1000 "Nominal density"
        annotation (Dialog(group="Nominal operating point",
                           enable=(CvData == ThermoPower.Choices.Valve.CvTypes.OpPoint)));
      parameter SI.PerUnit thetanom=1 "Nominal valve opening"
        annotation (Dialog(group="Nominal operating point"));
      parameter SI.Power Qnom=0 "Nominal heat loss to ambient"
        annotation (Dialog(group="Nominal operating point"), Evaluate=true);
      parameter Boolean CheckValve=false "Reverse flow stopped";
      parameter Real b=0.01 "Regularisation factor";
      replaceable function FlowChar =
          ThermoPower.Functions.ValveCharacteristics.linear
        constrainedby ThermoPower.Functions.ValveCharacteristics.baseFun
        "Flow characteristic"
        annotation (choicesAllMatching=true);
      parameter Boolean allowFlowReversal=system.allowFlowReversal
        "= true to allow flow reversal, false restricts to design direction"
      annotation(Evaluate=true);
      outer ThermoPower.System system "System wide properties";
      parameter Medium.AbsolutePressure pin_start=pnom
        "Inlet pressure start value"
        annotation (Dialog(tab="Initialisation"));
      parameter Medium.AbsolutePressure pout_start=pnom - dpnom
        "Inlet pressure start value"
        annotation (Dialog(tab="Initialisation"));
      Medium.MassFlowRate w "Mass flow rate";
      Units.LiquidDensity rho "Inlet density";
      Medium.Temperature Tin;
      SI.PressureDifference dp "Pressure drop across the valve";
      SI.PerUnit theta_act "Actual valve opening";
    protected
      function sqrtR = Functions.sqrtReg (delta=b*dpnom);
    public
      FlangeA inlet(
        m_flow(start=wnom, min=if allowFlowReversal then -Modelica.Constants.inf
               else 0),
        p(start=pin_start),
        redeclare package Medium = Medium) annotation (Placement(transformation(
              extent={{-120,-20},{-80,20}}, rotation=0)));
      FlangeB outlet(
        m_flow(start=-wnom, max=if allowFlowReversal then +Modelica.Constants.inf
               else 0),
        p(start=pout_start),
        redeclare package Medium = Medium) annotation (Placement(transformation(
              extent={{80,-20},{120,20}}, rotation=0)));
      Modelica.Blocks.Interfaces.RealInput theta if useThetaInput
        "Valve opening in per unit"
        annotation (Placement(transformation(
            origin={0,80},
            extent={{-20,-20},{20,20}},
            rotation=270)));
    protected
      Modelica.Blocks.Interfaces.RealInput theta_int
        "Protected connector for conditional input connector handling";

    initial equation
      if CvData == ThermoPower.Choices.Valve.CvTypes.Kv then
        Av = 2.7778e-5*Kv;
      elseif CvData == ThermoPower.Choices.Valve.CvTypes.Cv then
        Av = 2.4027e-5*Cv;
      end if;
      // assert(CvData>=0 and CvData<=3, "Invalid CvData");
    equation
      inlet.m_flow + outlet.m_flow = 0 "Mass balance";
      w = inlet.m_flow;

      // Fluid properties
      fluidState = Medium.setState_phX(inlet.p, inStream(inlet.h_outflow));
      Tin = Medium.temperature(fluidState);
      rho = Medium.density(fluidState);

      // Energy balance
      outlet.h_outflow = inStream(inlet.h_outflow) - Qnom/wnom;
      inlet.h_outflow = inStream(outlet.h_outflow) - Qnom/wnom;

      dp = inlet.p - outlet.p "Definition of dp";

      // Valve opening
      connect(theta, theta_int); // automatically removed if theta is disabled
      if not useThetaInput then
        theta_int = theta_fix;   // provide actual opening value from parameter
      end if;
      theta_act = theta_int;
      annotation (
        Icon(graphics={Text(extent={{-100,-40},{100,-80}}, textString="%name")}),
        Diagram(graphics),
        Documentation(info="<HTML>
<p>This is the base model for the <tt>ValveLiq</tt>, <tt>ValveLiqChoked</tt>, and <tt>ValveVap</tt> valve models. The model is based on the IEC 534 / ISA S.75 standards for valve sizing.
<p>The model optionally supports reverse flow conditions (assuming symmetrical behaviour) or check valve operation, and has been suitably modified to avoid numerical singularities at zero pressure drop.</p>
<p>An optional heat loss to the ambient can be included, proportional to the mass flow rate; <tt>Qnom</tt> specifies the heat loss at nominal flow rate.</p>
<p><b>Modelling options</b></p>
<p>The following options are available to specify the valve flow coefficient in fully open conditions:
<ul><li><tt>CvData = ThermoPower.Water.ValveBase.CvTypes.Av</tt>: the flow coefficient is given by the metric <tt>Av</tt> coefficient (m^2).
<li><tt>CvData = ThermoPower.Water.ValveBase.CvTypes.Kv</tt>: the flow coefficient is given by the metric <tt>Kv</tt> coefficient (m^3/h).
<li><tt>CvData = ThermoPower.Water.ValveBase.CvTypes.Cv</tt>: the flow coefficient is given by the US <tt>Cv</tt> coefficient (USG/min).
<li><tt>CvData = ThermoPower.Water.ValveBase.CvTypes.OpPoint</tt>: the flow coefficient is specified by the nominal operating point:  <tt>pnom</tt>, <tt>dpnom</tt>, <tt>wnom</tt>, <tt>rhonom</tt>, <tt>thetanom</tt> (in forward flow).
</ul>
<p>The nominal pressure drop <tt>dpnom</tt> must always be specified; to avoid numerical singularities, the flow characteristic is modified for pressure drops less than <tt>b*dpnom</tt> (the default value is 1% of the nominal pressure drop). Increase this parameter if numerical instabilities occur in valves with very low pressure drops.
<p>If <tt>CheckValve</tt> is true, then the flow is stopped when the outlet pressure is higher than the inlet pressure; otherwise, reverse flow takes place.
<p>The default flow characteristic <tt>FlowChar</tt> is linear; it can be replaced by functions taken from <tt>Functions.ValveCharacteristics</tt>, or by any suitable user-defined function extending <tt>Functions.ValveCharacteristics.baseFun</tt>.
</HTML>", revisions="<html>
<ul>
<li><i>17 Jul 2012</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Added heat loss to ambient (defaults to zero).</li>
<li><i>5 Nov 2005</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Moved replaceable characteristics to Function.ValveCharacteristics package.</li>
<li><i>29 Sep 2005</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Re-introduced valve sizing by an operating point.</li>
<li><i>6 Apr 2005</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Enumeration-type choice of CvData.</li>
<li><i>16 Dec 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Standard medium definition added.</li>
<li><i>18 Nov 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       <tt>Avnom</tt> removed; <tt>Av</tt> can now be set directly. <tt>Kvnom</tt> and <tt>Cvnom</tt> renamed to <tt>Kv</tt> and <tt>Cv</tt>.<br>
<tt>CvData=3</tt> no longer uses <tt>dpnom</tt>, <tt>wnom</tt> and <tt>rhonom</tt>, and requires an additional initial equation to set the flow coefficient based on the initial working conditions.
<li><i>1 Jul 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Valve models restructured using inheritance. <br>
       Adapted to Modelica.Media.</li>
<li><i>1 Oct 2003</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       First release.</li>
</ul>
</html>"));
    end ValveBase;

    partial model PumpBase "Base model for centrifugal pumps"
      extends Icons.Water.Pump;
      replaceable package Medium = StandardWater constrainedby
        Modelica.Media.Interfaces.PartialMedium "Medium model"
        annotation(choicesAllMatching = true);
      Medium.ThermodynamicState inletFluidState
        "Thermodynamic state of the fluid at the inlet";
      replaceable function flowCharacteristic =
          ThermoPower.Functions.PumpCharacteristics.baseFlow
        "Head vs. q_flow characteristic at nominal speed and density"
        annotation (Dialog(group="Characteristics"),choicesAllMatching=true);
      parameter Boolean usePowerCharacteristic=false
        "Use powerCharacteristic (vs. efficiencyCharacteristic)"
        annotation (Dialog(group="Characteristics"));
      replaceable function powerCharacteristic =
          Functions.PumpCharacteristics.constantPower constrainedby
        ThermoPower.Functions.PumpCharacteristics.basePower
        "Power consumption vs. q_flow at nominal speed and density" annotation (
         Dialog(group="Characteristics", enable=usePowerCharacteristic),
          choicesAllMatching=true);
      replaceable function efficiencyCharacteristic =
          Functions.PumpCharacteristics.constantEfficiency (eta_nom=0.8)
        constrainedby ThermoPower.Functions.PumpCharacteristics.baseEfficiency
        "Efficiency vs. q_flow at nominal speed and density" annotation (Dialog(
            group="Characteristics", enable=not usePowerCharacteristic),
          choicesAllMatching=true);
      parameter Integer Np0(min=1) = 1 "Nominal number of pumps in parallel";
      parameter Boolean use_in_Np = false
        "Use connector input for the pressure"
        annotation(Dialog(group="External inputs"), choices(checkBox=true));
      parameter Units.LiquidDensity rho0=1000 "Nominal Liquid Density"
        annotation (Dialog(group="Characteristics"));
      parameter NonSI.AngularVelocity_rpm n0 "Nominal rotational speed"
        annotation (Dialog(group="Characteristics"));
      parameter SI.Volume V=0 "Pump Internal Volume" annotation (Evaluate=true);
      parameter Boolean CheckValve=false "Reverse flow stopped";
      parameter Boolean allowFlowReversal=system.allowFlowReversal
        "= true to allow flow reversal, false restricts to design direction"
      annotation(Evaluate=true);
      outer ThermoPower.System system "System wide properties";
      parameter Medium.MassFlowRate wstart=w0 "Mass Flow Rate Start Value"
        annotation (Dialog(tab="Initialisation"));
      parameter Medium.SpecificEnthalpy hstart=1e5
        "Specific Enthalpy Start Value"
        annotation (Dialog(tab="Initialisation"));
      parameter Choices.Init.Options initOpt=system.initOpt
        "Initialisation option"
        annotation (Dialog(tab="Initialisation"));
      parameter Boolean noInitialPressure=false
        "Remove initial equation on pressure"
        annotation (Dialog(tab="Initialisation"),choices(checkBox=true));
      constant SI.Acceleration g=Modelica.Constants.g_n;
      parameter Medium.MassFlowRate w0 "Nominal mass flow rate"
        annotation (Dialog(group="Characteristics"));
      parameter SI.Pressure dp0 "Nominal pressure increase"
        annotation (Dialog(group="Characteristics"));
      final parameter SI.VolumeFlowRate q_single0=w0/(Np0*rho0)
        "Nominal volume flow rate (single pump)"
        annotation(Evaluate = true);
      final parameter SI.Height head0=dp0/(rho0*g) "Nominal pump head"
        annotation(Evaluate = true);
      final parameter Real d_head_dq_0=
        (flowCharacteristic(q_single0*1.05) - flowCharacteristic(q_single0*0.95))/
        (q_single0*0.1)
        "Approximate derivative of flow characteristic w.r.t. volume flow"
        annotation(Evaluate = true);
      final parameter Real d_head_dn_0 = 2/n0*head0 - q_single0/n0*d_head_dq_0
        "Approximate derivative of the flow characteristic w.r.t. rotational speed"
        annotation(Evaluate = true);

      Medium.MassFlowRate w_single(start=wstart/Np0)
        "Mass flow rate (single pump)";
      Medium.MassFlowRate w=Np*w_single "Mass flow rate (total)";
      SI.VolumeFlowRate q_single(start=wstart/(Np0*rho0))
        "Volume flow rate (single pump)";
      SI.VolumeFlowRate q=Np*q_single "Volume flow rate (total)";
      SI.PressureDifference dp "Outlet pressure minus inlet pressure";
      SI.Height head "Pump head";
      Medium.SpecificEnthalpy h(start=hstart) "Fluid specific enthalpy";
      Medium.SpecificEnthalpy hin "Enthalpy of entering fluid";
      Medium.SpecificEnthalpy hout "Enthalpy of outgoing fluid";
      Units.LiquidDensity rho "Liquid density";
      Medium.Temperature Tin "Liquid inlet temperature";
      NonSI.AngularVelocity_rpm n "Shaft r.p.m.";
      Integer Np(min=1) "Number of pumps in parallel";
      SI.Power W_single "Power Consumption (single pump)";
      SI.Power W=Np*W_single "Power Consumption (total)";
      SI.Power Qloss = 0 "Heat loss (single pump)";
      constant SI.Power W_eps=1e-8
        "Small coefficient to avoid numerical singularities";
      constant NonSI.AngularVelocity_rpm n_eps=1e-6;
      SI.PerUnit eta "Pump efficiency";
      SI.PerUnit s(start = 1) "Auxiliary non-dimensional variable";
      FlangeA infl(redeclare package Medium = Medium, m_flow(min=if
              allowFlowReversal then -Modelica.Constants.inf else 0))
        annotation (Placement(transformation(extent={{-100,0},{-60,40}},
              rotation=0)));
      FlangeB outfl(redeclare package Medium = Medium, m_flow(max=if
              allowFlowReversal then +Modelica.Constants.inf else 0))
        annotation (Placement(transformation(extent={{40,50},{80,90}}, rotation=
               0)));
      Modelica.Blocks.Interfaces.IntegerInput in_Np if use_in_Np
        "Number of  parallel pumps"
        annotation (Placement(transformation(
            origin={28,80},
            extent={{-10,-10},{10,10}},
            rotation=270)));
    protected
      Modelica.Blocks.Interfaces.IntegerInput int_Np
        "Internal connector with number of parallel pumps";

    equation
      // Flow equations
      q_single = w_single/homotopy(rho, rho0);
      head = dp/(homotopy(rho, rho0)*g);
      if noEvent(s > 0 or (not CheckValve)) then
        // Flow characteristics when check valve is open
        q_single = s*q_single0;
        head = homotopy((n/n0)^2*flowCharacteristic(q_single*n0/(n + n_eps)),
                         head0 + d_head_dq_0*(q_single - q_single0) +
                                 d_head_dn_0*(n - n0));
      else
        // Flow characteristics when check valve is closed
        head = homotopy((n/n0)^2*flowCharacteristic(0) - s*head0,
                         head0 + d_head_dq_0*(q_single - q_single0) +
                                 d_head_dn_0*(n - n0));
        q_single = 0;
      end if;

      // Power consumption
      if usePowerCharacteristic then
        W_single = (n/n0)^3*(rho/rho0)*
                    powerCharacteristic(q_single*n0/(n + n_eps))
          "Power consumption (single pump)";
        eta = (dp*q_single)/(W_single + W_eps) "Hydraulic efficiency";
      else
        eta = efficiencyCharacteristic(q_single*n0/(n + n_eps));
        W_single = dp*q_single/eta;
      end if;

      // Fluid properties
      inletFluidState = Medium.setState_phX(infl.p, hin);
      rho = Medium.density(inletFluidState);
      Tin = Medium.temperature(inletFluidState);

      // Boundary conditions
      dp = outfl.p - infl.p;
      w = infl.m_flow "Pump total flow rate";
      hin = homotopy(if not allowFlowReversal then inStream(infl.h_outflow)
                     else if w >= 0 then inStream(infl.h_outflow)
                     else inStream(outfl.h_outflow),
                     inStream(infl.h_outflow));
      infl.h_outflow = hout;
      outfl.h_outflow = hout;
      h = hout;

      // Mass and energy balances
      infl.m_flow + outfl.m_flow = 0 "Mass balance";
      if V > 0 then
        (rho*V*der(h)) = (outfl.m_flow/Np)*hout + (infl.m_flow/Np)*hin +
          W_single - Qloss "Energy balance";
      else
        0 = (outfl.m_flow/Np)*hout + (infl.m_flow/Np)*hin + W_single - Qloss
          "Energy balance";
      end if;

      // Number of pumps in parallel
      connect(in_Np, int_Np);
      if not use_in_Np then
        int_Np = Np0;
      end if;
      Np = int_Np;

    initial equation
      if initOpt == Choices.Init.Options.noInit then
        // do nothing
      elseif initOpt == Choices.Init.Options.fixedState then
        if V > 0 then
          h = hstart;
        end if;
      elseif initOpt == Choices.Init.Options.steadyState then
        if V > 0 then
          der(h) = 0;
        end if;
      else
        assert(false, "Unsupported initialisation option");
      end if;

      annotation (
        Icon(graphics),
        Diagram(graphics),
        Documentation(info="<HTML>
<p>This is the base model for the <tt>Pump</tt> and <tt>
PumpMech</tt> pump models.
<p>The model describes a centrifugal pump, or a group of <tt>Np</tt> identical pumps in parallel. The pump model is based on the theory of kinematic similarity: the pump characteristics are given for nominal operating conditions (rotational speed and fluid density), and then adapted to actual operating condition, according to the similarity equations.
<p>In order to avoid singularities in the computation of the outlet enthalpy at zero flowrate, the thermal capacity of the fluid inside the pump body can be taken into account.
<p>The model can either support reverse flow conditions or include a built-in check valve to avoid flow reversal.
<p><b>Modelling options</b></p>
<p> The nominal hydraulic characteristic (head vs. volume flow rate) is given by the the replaceable function <tt>flowCharacteristic</tt>.
<p> The pump energy balance can be specified in two alternative ways:
<ul>
<li><tt>usePowerCharacteristic = false</tt> (default option): the replaceable function <tt>efficiencyCharacteristic</tt> (efficiency vs. volume flow rate in nominal conditions) is used to determine the efficiency, and then the power consumption. The default is a constant efficiency of 0.8.
<li><tt>usePowerCharacteristic = true</tt>: the replaceable function <tt>powerCharacteristic</tt> (power consumption vs. volume flow rate in nominal conditions) is used to determine the power consumption, and then the efficiency.
</ul>
<p>
Several functions are provided in the package <tt>Functions.PumpCharacteristics</tt> to specify the characteristics as a function of some operating points at nominal conditions.
<p>Depending on the value of the <tt>checkValve</tt> parameter, the model either supports reverse flow conditions, or includes a built-in check valve to avoid flow reversal.

<p>If the <tt>in_Np</tt> input connector is wired, it provides the number of pumps in parallel; otherwise,  <tt>Np0</tt> parallel pumps are assumed.</p>
<p>It is possible to take into account the heat capacity of the fluid inside the pump by specifying its volume <tt>V</tt> at nominal conditions; this is necessary to avoid singularities in the computation of the outlet enthalpy in case of zero flow rate. If zero flow rate conditions are always avoided, this dynamic effect can be neglected by leaving the default value <tt>V = 0</tt>, thus avoiding a fast state variable in the model.
<p>The <tt>CheckValve</tt> parameter determines whether the pump has a built-in check valve or not.
<p>If <tt>computeNPSHa = true</tt>, the available net positive suction head is also computed; this requires a two-phase medium model to provide the fluid saturation pressure.
</HTML>", revisions="<html>
<ul>
<li><i>31 Oct 2006</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
      Added initialisation parameter <tt>wstart</tt>.</li>
<li><i>5 Nov 2005</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
      Model restructured according to kinematic similarity theory.<br>
      Characteristics now specified by replaceable functions.</li>
<li><i>6 Apr 2005</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       <tt>CharData</tt> substituted by <tt>OpPoints</tt></li>
<li><i>16 Dec 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Standard medium definition added.</li>
<li><i>2 Aug 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Optional NPSHa computation added. Changed parameter names</li>
<li><i>5 Jul 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Model restructured by using inheritance. Adapted to Modelica.Media.</li>
<li><i>15 Jan 2004</i>
    by <a href=\"mailto:francesco.schiavo@polimi.it\">Francesco Schiavo</a>:<br>
       <tt>ThermalCapacity</tt> and <tt>CheckValve</tt> added.</li>
<li><i>15 Dec 2003</i>
    by <a href=\"mailto:francesco.schiavo@polimi.it\">Francesco Schiavo</a>:<br>
       First release.</li>
</ul>
</html>"));
    end PumpBase;

    partial model SteamTurbineBase "Steam turbine"
      replaceable package Medium = ThermoPower.Water.StandardWater
        constrainedby Modelica.Media.Interfaces.PartialMedium "Medium model"
        annotation(choicesAllMatching = true);
      parameter Boolean explicitIsentropicEnthalpy=true
        "Outlet enthalpy computed by isentropicEnthalpy function";
      parameter Medium.MassFlowRate wstart=wnom "Mass flow rate start value"
        annotation (Dialog(tab="Initialisation"));
      parameter SI.PerUnit PRstart "Pressure ratio start value"
        annotation (Dialog(tab="Initialisation"));
      parameter Medium.MassFlowRate wnom "Inlet nominal flowrate";
      parameter Medium.AbsolutePressure pnom "Nominal inlet pressure";
      parameter Real eta_mech=0.98 "Mechanical efficiency";
      parameter Boolean usePartialArcInput = false
        "Use the input connector for the partial arc opening";

      outer ThermoPower.System system "System wide properties";

      Medium.ThermodynamicState steamState_in;
      Medium.ThermodynamicState steamState_iso;

      SI.Angle phi(start=0) "shaft rotation angle";
      SI.Torque tau "net torque acting on the turbine";
      SI.AngularVelocity omega "shaft angular velocity";
      Medium.MassFlowRate w "Mass flow rate";
      Medium.SpecificEnthalpy hin "Inlet enthalpy";
      Medium.SpecificEnthalpy hout "Outlet enthalpy";
      Medium.SpecificEnthalpy hiso "Isentropic outlet enthalpy";
      Medium.SpecificEntropy sin "Inlet entropy";
      Medium.AbsolutePressure pin(start=pnom) "Outlet pressure";
      Medium.AbsolutePressure pout(start=pnom/PRstart) "Outlet pressure";
      SI.PerUnit PR "pressure ratio";
      SI.Power Pm "Mechanical power input";
      SI.PerUnit eta_iso "Isentropic efficiency";
      SI.PerUnit theta "Partial arc opening in p.u.";

      Modelica.Blocks.Interfaces.RealInput partialArc if usePartialArcInput
        "Partial arc opening in p.u." annotation (Placement(
            transformation(extent={{-60,-50},{-40,-30}}, rotation=0)));
      Modelica.Mechanics.Rotational.Interfaces.Flange_a shaft_a annotation (
          Placement(transformation(extent={{-76,-10},{-56,10}}, rotation=0)));
      Modelica.Mechanics.Rotational.Interfaces.Flange_b shaft_b annotation (
          Placement(transformation(extent={{54,-10},{74,10}}, rotation=0)));
      FlangeA inlet(redeclare package Medium = Medium, m_flow(min=0))
        annotation (Placement(transformation(extent={{-100,60},{-60,100}},
              rotation=0)));
      FlangeB outlet(redeclare package Medium = Medium, m_flow(max=0))
        annotation (Placement(transformation(extent={{60,60},{100,100}},
              rotation=0)));
    protected
      Modelica.Blocks.Interfaces.RealInput partialArc_int "Internal connector for partial arc input";
    equation
      PR = pin/pout "Pressure ratio";
      theta = partialArc_int;
      if not usePartialArcInput then
        partialArc_int = 1 "Default value if not connector input is disabled";
        // otherwise partialArc_int is connected to partialArc input connector
      end if;
      if explicitIsentropicEnthalpy then
        hiso = Medium.isentropicEnthalpy(pout, steamState_in)
          "Isentropic enthalpy";
        //dummy assignments
        sin = 0;
        steamState_iso = Medium.setState_phX(Medium.p_default,Medium.h_default);
      else
        sin = Medium.specificEntropy(steamState_in);
        steamState_iso = Medium.setState_ps(pout, sin);
        hiso = Medium.specificEnthalpy(steamState_iso);
      end if;
      hin - hout = eta_iso*(hin - hiso) "Computation of outlet enthalpy";
      Pm = eta_mech*w*(hin - hout) "Mechanical power from the steam";
      Pm = -tau*omega "Mechanical power balance";

      inlet.m_flow + outlet.m_flow = 0 "Mass balance";

      assert(w >= -wnom/100, "The turbine model does not support flow reversal");

      // Mechanical boundary conditions
      shaft_a.phi = phi;
      shaft_b.phi = phi;
      shaft_a.tau + shaft_b.tau = tau;
      der(phi) = omega;

      // steam boundary conditions and inlet steam properties
      steamState_in = Medium.setState_phX(pin, inStream(inlet.h_outflow));
      hin = inStream(inlet.h_outflow);
      hout = outlet.h_outflow;
      pin = inlet.p;
      pout = outlet.p;
      w = inlet.m_flow;

      // The next equation is provided to close the balance but never actually used
      inlet.h_outflow = outlet.h_outflow;
      connect(partialArc, partialArc_int);
      annotation (
        Icon(graphics={
            Polygon(
              points={{-28,76},{-28,28},{-22,28},{-22,82},{-60,82},{-60,76},{-28,
                  76}},
              lineColor={0,0,0},
              lineThickness=0.5,
              fillColor={0,0,255},
              fillPattern=FillPattern.Solid),
            Polygon(
              points={{26,56},{32,56},{32,76},{60,76},{60,82},{26,82},{26,56}},
              lineColor={0,0,0},
              lineThickness=0.5,
              fillColor={0,0,255},
              fillPattern=FillPattern.Solid),
            Rectangle(
              extent={{-60,8},{60,-8}},
              lineColor={0,0,0},
              fillPattern=FillPattern.Sphere,
              fillColor={160,160,164}),
            Polygon(
              points={{-28,28},{-28,-26},{32,-60},{32,60},{-28,28}},
              lineColor={0,0,0},
              lineThickness=0.5,
              fillColor={0,0,255},
              fillPattern=FillPattern.Solid),
            Text(extent={{-130,-60},{128,-100}}, textString="%name")}),
        Diagram(graphics),
        Documentation(info="<html>
<p>This base model contains the basic interface, parameters and definitions for steam turbine models. It lacks the actual performance characteristics, i.e. two more equations to determine the flow rate and the efficiency.
<p>This model does not include any shaft inertia by itself; if that is needed, connect a <tt>Modelica.Mechanics.Rotational.Inertia</tt> model to one of the shaft connectors.
<p><b>Modelling options</b></p>
<p>The following options are available to calculate the enthalpy of the outgoing steam:
<ul><li><tt>explicitIsentropicEnthalpy = true</tt>: the isentropic enthalpy <tt>hout_iso</tt> is calculated by the <tt>Medium.isentropicEnthalpy</tt> function. <li><tt>explicitIsentropicEnthalpy = false</tt>: the isentropic enthalpy is given equating the specific entropy of the inlet steam <tt>steam_in</tt> and of a fictional steam state <tt>steam_iso</tt>, which has the same pressure of the outgoing steam, both computed with the function <tt>Medium.specificEntropy</tt>.</pp></ul>
</html>", revisions="<html>
<ul>
<li><i>20 Apr 2005</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       First release.</li>
<li><i>5 Oct 2011</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Small changes in alias variables.</li>
</ul>
</html>"));
    end SteamTurbineBase;

    partial model EvaporatorBase
      "Basic interface for 1-dimensional water/steam fluid flow models"
      replaceable package Medium = StandardWater constrainedby
        Modelica.Media.Interfaces.PartialTwoPhaseMedium "Medium model";
      Medium.BaseProperties fluid_in "Fluid properties at the inlet";
      Medium.BaseProperties fluid_out "Fluid properties at the outlet";
      Medium.SaturationProperties sat "Saturation properties";
      extends Icons.Water.Tube;
      parameter Integer N(min=2) = 2 "Number of nodes for thermal variables";
      parameter Integer Nt=1 "Number of tubes in parallel";
      parameter SI.Distance L "Tube length";
      parameter SI.Position H=0 "Elevation of outlet over inlet";
      parameter SI.Area A "Cross-sectional area (single tube)";
      parameter SI.Length omega
        "Perimeter of heat transfer surface (single tube)";
      parameter SI.Length Dhyd "Hydraulic Diameter (single tube)";
      parameter SI.MassFlowRate wnom "Nominal mass flowrate (total)";
      parameter Integer FFtype
        "Friction Factor Type (0: Kf; 1:OpPoint, 2:Cfnom, 3:Colebrook)";
      parameter Real Kfnom=0 "Nominal hydraulic resistance coefficient";
      parameter SI.Pressure dpnom=0
        "Nominal pressure drop (friction term only!)";
      parameter Medium.Density rhonom=0 "Nominal inlet density";
      parameter SI.PerUnit Cfnom=0 "Nominal Fanning friction factor";
      parameter SI.PerUnit e=0 "Relative roughness (ratio roughness/diameter)";
      parameter Boolean DynamicMomentum=false
        "Inertial phenomena accounted for";
      parameter Integer HydraulicCapacitance=2 "1: Upstream, 2: Downstream";
      parameter SI.Length csilstart "Liquid boundary start position";
      parameter SI.Length csivstart "Vapour boundary start position";
      parameter Medium.SpecificEnthalpy hstartin=1e5
        "Inlet enthalpy start value";
      parameter Medium.SpecificEnthalpy hstartout=1e5
        "Outlet enthalpy start value";
      parameter Medium.AbsolutePressure pstartin=1e5
        "Inlet pressure start value";
      parameter Medium.AbsolutePressure pstartout=1e5
        "Outlet pressure start value";
      parameter Real wnf=0.01
        "Fraction of nominal flow rate at which linear friction equals turbulent friction";
      parameter SI.PerUnit Kfc=1 "Friction factor correction coefficient";
      constant SI.Acceleration g=Modelica.Constants.g_n;
      /*
  FlangeA infl(p(start=pstartin),w(start=wnom),hAB(start=hstartin),
    redeclare package Medium = Medium)
    annotation (extent=[-120, -20; -80, 20]);
  FlangeB outfl(p(start=pstartout),w(start=-wnom),hBA(start=hstartout),
    redeclare package Medium = Medium)
    annotation (extent=[80, -20; 120, 20]);
  replaceable ThermoPower.Thermal.DHT wall(N=N)
    annotation (extent=[-40, 40; 40, 60]);
*/
      Medium.AbsolutePressure p(start=pstartin, stateSelect=StateSelect.prefer);
      Medium.MassFlowRate win(start=wnom) "Inlet flow rate";
      Medium.MassFlowRate wlb(start=wnom)
        "Flowrate from liquid volume to boiling volume";
      Medium.MassFlowRate wbv(start=wnom)
        "Flowrate from boiling volume to vapour volume";
      Medium.MassFlowRate wout(start=wnom) "Outlet flow rate";
      Medium.SpecificEnthalpy hin(start=hstartin) "Inlet specific enthalpy";
      Medium.SpecificEnthalpy hout(start=hstartout, stateSelect=StateSelect.prefer)
        "Outlet specific enthalpy";
      Medium.SpecificEnthalpy hls "Saturated liquid specific enthalpy";
      Medium.SpecificEnthalpy hvs "Saturated vapour specific enthalpy";
      Medium.SpecificEnthalpy hlb;
      Medium.SpecificEnthalpy hbv;
      Medium.Density rhoin "Inlet density";
      Medium.Density rhoout "Outlet density";
      Medium.Density rhols "Saturated liquid density";
      Medium.Density rhovs "Saturated vapour density";
      SI.Volume Vl "Liquid volume";
      SI.Volume Vb "Boiling volume";
      SI.Volume Vv "Vapour volume";
      SI.Mass Ml "Mass of the liquid volume";
      SI.Mass Mb "Mass of the boiling volume";
      SI.Mass Mbl "Mass of liquid in the boiling volume";
      SI.Mass Mbv "Mass of vapour in the boiling volume";
      SI.Mass Mv "Mass of the vapour volume";
      SI.Energy El "Energy of the liquid volume";
      SI.Energy Eb "Energy of the boiling volume";
      SI.Energy Ev "Energy of the vapour volume";
      SI.Power Q "Total power balance";
      Medium.MassFlowRate M_flow "Total mass flow balance";
      SI.Power Ql "Thermal power to the liquid volume";
      SI.Power Qb "Thermal power to the boiling volume";
      SI.Power Qv "Thermal power to the vapour volume";
      SI.Length csil(start=csilstart, stateSelect=StateSelect.prefer)
        "Abscissa of liqid boundary";
      SI.Length csiv(start=csivstart, stateSelect=StateSelect.prefer)
        "Abscissa of vapour boundary";
      SI.Time Tr "Residence time";

    equation
      Vl = A*csil "Volume of subcooled liquid";
      Vb = A*(csiv - csil) "Volume of boiling liquid";
      Vv = A*(L - csiv) "Volume of superheated vapour";
      Ml = (rhoin + (if hout > hls then rhols else rhoout))/2*Vl
        "Mass of subcooled liquid";
      Mb = (if (hout > hvs) then rhols*rhovs/(rhols - rhovs)*log(rhols/rhovs)
         else if (hout > hls + 1e-3) then rhols*rhoout/(rhols - rhoout)*log(rhols
        /rhoout) else rhols)*Vb "Mass of boiling liquid";
      Mbv = (if (hout > hvs) then rhols*rhovs/(rhols - rhovs)*(1 - rhovs/(rhols
         - rhovs)*log(rhols/rhovs)) else if (hout > hls + 1e-3) then rhols*rhovs/
        (rhols - rhovs)*(1 - rhoout/(rhols - rhoout)*log(rhols/rhoout)) else if (
        hout > hls) then rhovs/(rhols - rhovs)*(rhols - rhoout)/2 else 0)*Vb
        "Mass of vapour in boiling liquid";
      Mbl = Mb - Mbv "Mass of liquid in boiling liquid";
      Mv = Vv*(rhovs + rhoout)/2 "Mass of superheated vapour";
      El = Ml*(hin + (if hout > hls then hls else hout))/2 - p*Vl
        "Energy of subcooled liquid";
      Eb = Mbl*hls + Mbv*hvs - p*Vb "Energy of boiling water";
      Ev = Mv*(hvs + hout)/2 - p*Vv "Energy of superheated vapour";
      der(Ml) = win - wlb "Liquid volume mass balance";
      if hout > hls then
        der(Mb) = wlb - wbv "Boiling volume mass balance";
      else
        der(csil) = 0;
      end if;
      if hout > hvs then
        der(Mv) = wbv - wout "Superheated volume mass balance";
      else
        der(csiv) = 0;
      end if;
      der(El) = win*hin - wlb*hlb - p*der(Vl) + Ql
        "Liquid volume energy balance";
      if hout > hls then
        der(Eb) = wlb*hlb - wbv*hbv - p*der(Vb) + Qb
          "Boiling volume energy balance";
      else
        wlb = wout;
      end if;
      if hout > hvs then
        der(Ev) = wbv*hbv - wout*hout - p*der(Vv) + Qv
          "Superheated volume energy balance";
      else
        wbv = wout;
      end if;
      hlb = if (hout > hls) then hls else hout
        "Enthalpy at the liquid-boiling interface";
      hbv = if (hout > hvs) then hvs else hout
        "Enthalpy at the boiling-vapour interface";
      Tr = (Ml + Mb + Mv)/win "Residence time";

      // Fluid properties
      sat.psat = p;
      sat.Tsat = Medium.saturationTemperature(p);
      fluid_in.p = p;
      fluid_in.h = hin;
      fluid_out.p = p;
      fluid_out.h = hout;

      rhoin = fluid_in.d;
      rhoout = fluid_out.d;
      rhols = Medium.bubbleDensity(sat);
      rhovs = Medium.dewDensity(sat);
      hls = Medium.bubbleEnthalpy(sat);
      hvs = Medium.dewEnthalpy(sat);

      // Temporary boundary conditions
      Q = Ql + Qb + Qv + win*hin - wout*hout - der(El) - der(Eb) - der(Ev);
      M_flow = win - wout - der(Ml) - der(Mb) - der(Mv);
      annotation (Documentation(info="<html>
This model is not yet complete
</html>"));
    end EvaporatorBase;
  end BaseClasses;

  model Drum2States
    extends Icons.Water.Drum;
    extends Modelica.Icons.ObsoleteModel;
    replaceable package Medium = StandardWater constrainedby
      Modelica.Media.Interfaces.PartialTwoPhaseMedium "Medium model"
      annotation(choicesAllMatching = true);
    parameter SI.Volume Vd "Drum volume";
    parameter SI.Volume Vdcr "Volume of downcomer and risers";
    parameter SI.Mass Mmd "Drum metal mass";
    parameter SI.Mass Mmdcr "Metal mass of downcomer and risers";
    parameter Medium.SpecificHeatCapacity cm
      "Specific heat capacity of the metal";
    parameter Boolean allowFlowReversal=system.allowFlowReversal
      "= true to allow flow reversal, false restricts to design direction"
      annotation(Evaluate=true);
    outer ThermoPower.System system "System wide properties";
    parameter SI.Pressure pstart "Pressure start value"
      annotation (Dialog(tab="Initialisation"));
    parameter SI.Volume Vldstart "Start value of drum water volume"
      annotation (Dialog(tab="Initialisation"));
    parameter Choices.Init.Options initOpt=system.initOpt
      "Initialisation option"
      annotation (Dialog(tab="Initialisation"));
    parameter Boolean noInitialPressure=false
      "Remove initial equation on pressure"
      annotation (Dialog(tab="Initialisation"),choices(checkBox=true));

    Medium.SaturationProperties sat "Saturation conditions";
    FlangeA feed(redeclare package Medium = Medium, m_flow(min=if
            allowFlowReversal then -Modelica.Constants.inf else 0)) annotation (
       Placement(transformation(extent={{-110,-64},{-70,-24}}, rotation=0)));
    FlangeB steam(redeclare package Medium = Medium, m_flow(max=if
            allowFlowReversal then +Modelica.Constants.inf else 0)) annotation (
       Placement(transformation(extent={{48,52},{88,92}}, rotation=0)));
    Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_a heat
      "Metal wall thermal port" annotation (Placement(transformation(extent={{-28,
              -100},{28,-80}}, rotation=0)));
    SI.Mass Ml "Liquid water mass";
    SI.Mass Mv "Steam mass";
    SI.Mass M "Total liquid+steam mass";
    SI.Energy E "Total energy";
    SI.Volume Vt "Total volume";
    SI.Volume Vl(start=Vldstart + Vdcr) "Liquid water total volume";
    SI.Volume Vld(start=Vldstart, stateSelect=StateSelect.prefer)
      "Liquid water volume in the drum";
    SI.Volume Vv "Steam volume";
    Medium.AbsolutePressure p(start=pstart,stateSelect=StateSelect.prefer)
      "Drum pressure";
    Medium.MassFlowRate qf "Feedwater mass flowrate";
    Medium.MassFlowRate qs "Steam mass flowrate";
    SI.HeatFlowRate Q "Heat flow to the risers";
    Medium.SpecificEnthalpy hf "Feedwater specific enthalpy";
    Medium.SpecificEnthalpy hl "Specific enthalpy of saturated liquid";
    Medium.SpecificEnthalpy hv "Specific enthalpy of saturated steam";
    Medium.Temperature Ts "Saturation temperature";
    Units.LiquidDensity rhol "Density of saturated liquid";
    Units.GasDensity rhov "Density of saturated steam";
  equation
    Ml = Vl*rhol "Mass of liquid";
    Mv = Vv*rhov "Mass of vapour";
    M = Ml + Mv "Total mass";
    E = Ml*hl + Mv*hv - p*Vt + (Mmd + Mmdcr)*cm*Ts "Total energy";
    Ts = sat.Tsat "Saturation temperature";
    der(M) = qf - qs "Mass balance";
    der(E) = Q + qf*hf - qs*hv "Energy balance";
    Vl = Vld + Vdcr "Liquid volume";
    Vt = Vd + Vdcr "Total volume";
    Vt = Vl + Vv "Total volume";

    // Boundary conditions
    p = feed.p;
    p = steam.p;
    hf = homotopy(if not allowFlowReversal then inStream(feed.h_outflow) else
      actualStream(feed.h_outflow), inStream(feed.h_outflow));
    feed.m_flow = qf;
    -steam.m_flow = qs;
    feed.h_outflow = hl;
    steam.h_outflow = hv;
    Q = heat.Q_flow;
    heat.T = Ts;

    // Fluid properties
    sat.psat = p;
    sat.Tsat = Medium.saturationTemperature(p);
    rhol = Medium.bubbleDensity(sat);
    rhov = Medium.dewDensity(sat);
    hl = Medium.bubbleEnthalpy(sat);
    hv = Medium.dewEnthalpy(sat);
  initial equation
    if initOpt == Choices.Init.Options.noInit then
      // do nothing
    elseif initOpt == Choices.Init.Options.fixedState then
      if not noInitialPressure then
        p = pstart;
      end if;
      Vld = Vldstart;
    elseif initOpt == Choices.Init.Options.steadyState then
      if not noInitialPressure then
        der(p) = 0;
      end if;
      der(Vld) = 0;
    else
      assert(false, "Unsupported initialisation option");
    end if;
    annotation (
      Diagram(graphics),
      Documentation(info="<HTML>
<p>Simplified model of a drum for drum boilers. This model assumes thermodynamic equilibrium between the liquid and vapour volumes. The model has two state variables (i.e., pressure and liquid volume).
</HTML>", revisions="<html>
<ul>
<li><i>30 May 2005</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Initialisation support added.</li>
<li><i>16 Dec 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Standard medium definition added.</li>
<li><i>24 Sep 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Adapted to Modelica.Media.</li>
<li><i>1 May 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       First release.</li>
</ul>
</html>"),
      Icon(graphics));
  end Drum2States;

  model Flow1D
    "1-dimensional fluid flow model for water/steam (finite volumes)"
    extends BaseClasses.Flow1DBase;
    extends Modelica.Icons.ObsoleteModel;
    replaceable ThermoPower.Thermal.DHT wall(N=N) annotation (Dialog(enable=
            false), Placement(transformation(extent={{-40,40},{40,60}},
            rotation=0)));
    import ThermoPower.Choices.Flow1D.FFtypes;
    import ThermoPower.Choices.Flow1D.HCtypes;
    Medium.ThermodynamicState fluidState[N]
      "Thermodynamic state of the fluid at the nodes";
    SI.Length omega_hyd "Wet perimeter (single tube)";
    SI.Pressure Dpfric "Pressure drop due to friction (total)";
    SI.Pressure Dpfric1
      "Pressure drop due to friction (from inlet to capacitance)";
    SI.Pressure Dpfric2
      "Pressure drop due to friction (from capacitance to outlet)";
    SI.Pressure Dpstat "Pressure drop due to static head";
    SI.MassFlowRate win "Flow rate at the inlet (single tube)";
    SI.MassFlowRate wout "Flow rate at the outlet (single tube)";
    Real Kf "Hydraulic friction coefficient";
    Real dwdt "Dynamic momentum term";
    Real Cf "Fanning friction factor";
    Medium.AbsolutePressure p(start=pstart)
      "Fluid pressure for property calculations";
    SI.MassFlowRate w(start=wnom/Nt) "Mass flowrate (single tube)";
    SI.MassFlowRate wbar[N - 1](each start=wnom/Nt);
    SI.Velocity u[N] "Fluid velocity";
    Medium.Temperature T[N] "Fluid temperature";
    Medium.SpecificEnthalpy h[N](start=hstart)
      "Fluid specific enthalpy at the nodes";
    Medium.SpecificEnthalpy htilde[N - 1](start=hstart[2:N])
      "Enthalpy state variables";
    Medium.Density rho[N] "Fluid nodal density";
    SI.Mass M "Fluid mass";
    Real dMdt[N - 1] "Time derivative of mass in each cell between two nodes";
  protected
    SI.Density rhobar[N - 1] "Fluid average density";
    SI.SpecificVolume vbar[N - 1] "Fluid average specific volume";
    SI.HeatFlux phibar[N - 1] "Average heat flux";
    SI.DerDensityByEnthalpy drdh[N] "Derivative of density by enthalpy";
    SI.DerDensityByEnthalpy drbdh[N - 1]
      "Derivative of average density by enthalpy";
    SI.DerDensityByPressure drdp[N] "Derivative of density by pressure";
    SI.DerDensityByPressure drbdp[N - 1]
      "Derivative of average density by pressure";
  equation
    //All equations are referred to a single tube
    // Friction factor selection
    omega_hyd = 4*A/Dhyd;
    if FFtype == FFtypes.Kfnom then
      Kf = Kfnom*Kfc;
    elseif FFtype == FFtypes.OpPoint then
      Kf = dpnom*rhonom/(wnom/Nt)^2*Kfc;
    elseif FFtype == FFtypes.Cfnom then
      Cf = Cfnom*Kfc;
    elseif FFtype == FFtypes.Colebrook then
      Cf = f_colebrook(
          w,
          Dhyd/A,
          e,
          Medium.dynamicViscosity(fluidState[integer(N/2)]))*Kfc;
    elseif FFtype == FFtypes.NoFriction then
      Cf = 0;
    end if;
    Kf = Cf*omega_hyd*L/(2*A^3)
      "Relationship between friction coefficient and Fanning friction factor";
    assert(Kf >= 0, "Negative friction coefficient");

    // Dynamic momentum term
    if DynamicMomentum then
      dwdt = der(w);
    else
      dwdt = 0;
    end if;

    sum(dMdt) = (infl.m_flow + outfl.m_flow)/Nt "Mass balance";
    L/A*dwdt + (outfl.p - infl.p) + Dpstat + Dpfric = 0 "Momentum balance";
    Dpfric = Dpfric1 + Dpfric2 "Total pressure drop due to friction";
    if FFtype == FFtypes.NoFriction then
      Dpfric1 = 0;
      Dpfric2 = 0;
    elseif HydraulicCapacitance == HCtypes.Middle then
      //assert((N-1)-integer((N-1)/2)*2 == 0, "N must be odd");
      Dpfric1 = homotopy(Kf*squareReg(win, wnom/Nt*wnf)*sum(vbar[1:integer((N
         - 1)/2)])/(N - 1), dpnom/2/(wnom/Nt)*win)
        "Pressure drop from inlet to capacitance";
      Dpfric2 = homotopy(Kf*squareReg(wout, wnom/Nt*wnf)*sum(vbar[1 + integer((
        N - 1)/2):N - 1])/(N - 1), dpnom/2/(wnom/Nt)*wout)
        "Pressure drop from capacitance to outlet";
    elseif HydraulicCapacitance == HCtypes.Upstream then
      Dpfric1 = 0 "Pressure drop from inlet to capacitance";
      Dpfric2 = homotopy(Kf*squareReg(wout, wnom/Nt*wnf)*sum(vbar)/(N - 1),
        dpnom/(wnom/Nt)*wout) "Pressure drop from capacitance to outlet";
    elseif HydraulicCapacitance == HCtypes.Downstream then
      Dpfric1 = homotopy(Kf*squareReg(win, wnom/Nt*wnf)*sum(vbar)/(N - 1),
        dpnom/(wnom/Nt)*win) "Pressure drop from inlet to capacitance";
      Dpfric2 = 0 "Pressure drop from capacitance to outlet";
    else
      assert(false, "Unsupported HydraulicCapacitance option");
    end if "Pressure drop due to friction";
    Dpstat = if abs(dzdx) < 1e-6 then 0 else g*l*dzdx*sum(rhobar)
      "Pressure drop due to static head";
    for j in 1:N - 1 loop
      if Medium.singleState then
        A*l*rhobar[j]*der(htilde[j]) + wbar[j]*(h[j + 1] - h[j]) = l*omega*
          phibar[j] "Energy balance (pressure effects neglected)";
      else
        A*l*rhobar[j]*der(htilde[j]) + wbar[j]*(h[j + 1] - h[j]) - A*l*der(p) =
          l*omega*phibar[j] "Energy balance";
      end if;
      dMdt[j] = A*l*(drbdh[j]*der(htilde[j]) + drbdp[j]*der(p))
        "Mass derivative for each volume";
      // Average volume quantities
      rhobar[j] = (rho[j] + rho[j + 1])/2;
      drbdp[j] = (drdp[j] + drdp[j + 1])/2;
      drbdh[j] = (drdh[j] + drdh[j + 1])/2;
      vbar[j] = 1/rhobar[j];
      wbar[j] = homotopy(infl.m_flow/Nt - sum(dMdt[1:j - 1]) - dMdt[j]/2, wnom/
        Nt);
    end for;

    // Fluid property calculations
    for j in 1:N loop
      fluidState[j] = Medium.setState_phX(p, h[j]);
      T[j] = Medium.temperature(fluidState[j]);
      rho[j] = Medium.density(fluidState[j]);
      drdp[j] = if Medium.singleState then 0 else Medium.density_derp_h(
        fluidState[j]);
      drdh[j] = Medium.density_derh_p(fluidState[j]);
      u[j] = w/(rho[j]*A);
    end for;

    // Boundary conditions
    win = infl.m_flow/Nt;
    wout = -outfl.m_flow/Nt;
    if HydraulicCapacitance == HCtypes.Middle then
      p = infl.p - Dpfric1 - Dpstat/2;
      w = win;
    elseif HydraulicCapacitance == HCtypes.Upstream then
      p = infl.p;
      w = -outfl.m_flow/Nt;
    elseif HydraulicCapacitance == HCtypes.Downstream then
      p = outfl.p;
      w = win;
    else
      assert(false, "Unsupported HydraulicCapacitance option");
    end if;
    infl.h_outflow = htilde[1];
    outfl.h_outflow = htilde[N - 1];

    h[1] = inStream(infl.h_outflow);
    h[2:N] = htilde;

    T = wall.T;
    phibar = (wall.phi[1:N - 1] + wall.phi[2:N])/2;

    Q = Nt*l*omega*sum(phibar) "Total heat flow through lateral boundary";
    M = sum(rhobar)*A*l "Total fluid mass";
    Tr = noEvent(M/max(win, Modelica.Constants.eps)) "Residence time";
  initial equation
    if initOpt == Choices.Init.Options.noInit then
      // do nothing
    elseif initOpt == Choices.Init.Options.steadyState then
      der(htilde) = zeros(N - 1);
      if (not Medium.singleState) then
        der(p) = 0;
      end if;
    elseif initOpt == Choices.Init.Options.steadyStateNoP then
      der(htilde) = zeros(N - 1);
    elseif initOpt == Choices.Init.Options.steadyStateNoT and not Medium.singleState then
      der(p) = 0;
    else
      assert(false, "Unsupported initialisation option");
    end if;
    annotation (
      Diagram(graphics),
      Icon(graphics={Text(extent={{-100,-52},{100,-80}}, textString="%name")}),
      Documentation(info="<HTML>
<p>This model describes the flow of water or steam in a rigid tube. The basic modelling assumptions are:
<ul><li>The fluid state is always one-phase (i.e. subcooled liquid or superheated steam).
<li>Uniform velocity is assumed on the cross section, leading to a 1-D distributed parameter model.
<li>Turbulent friction is always assumed; a small linear term is added to avoid numerical singularities at zero flowrate. The friction effects are not accurately computed in the laminar and transitional flow regimes, which however should not be an issue in most applications using water or steam as a working fluid.
<li>The model is based on dynamic mass, momentum, and energy balances. The dynamic momentum term can be switched off, to avoid the fast oscillations that can arise from its coupling with the mass balance (sound wave dynamics).
<li>The longitudinal heat diffusion term is neglected.
<li>The energy balance equation is written by assuming a uniform pressure distribution; the compressibility effects are lumped at the inlet, at the outlet, or at the middle of the pipe.
<li>The fluid flow can exchange thermal power through the lateral surface, which is represented by the <tt>wall</tt> connector. The actual heat flux must be computed by a connected component (heat transfer computation module).
</ul>
<p>The mass, momentum and energy balance equation are discretised with the finite volume method. The state variables are one pressure, one flowrate (optional) and N-1 specific enthalpies.
<p>The turbulent friction factor can be either assumed as a constant, or computed by Colebrook's equation. In the former case, the friction factor can be supplied directly, or given implicitly by a specified operating point. In any case, the multiplicative correction coefficient <tt>Kfc</tt> can be used to modify the friction coefficient, e.g. to fit experimental data.
<p>A small linear pressure drop is added to avoid numerical singularities at low or zero flowrate. The <tt>wnom</tt> parameter must be always specified: the additional linear pressure drop is such that it is equal to the turbulent pressure drop when the flowrate is equal to <tt>wnf*wnom</tt> (the default value is 1% of the nominal flowrate). Increase <tt>wnf</tt> if numerical instabilities occur in tubes with very low pressure drops.
<p>Flow reversal is fully supported.
<p><b>Modelling options</b></p>
<p>Thermal variables (enthalpy, temperature, density) are computed in <tt>N</tt> equally spaced nodes, including the inlet (node 1) and the outlet (node N); <tt>N</tt> must be greater than or equal to 2.
<p>The following options are available to specify the friction coefficient:
<ul><li><tt>FFtype = FFtypes.Kfnom</tt>: the hydraulic friction coefficient <tt>Kf</tt> is set directly to <tt>Kfnom</tt>.
<li><tt>FFtype = FFtypes.OpPoint</tt>: the hydraulic friction coefficient is specified by a nominal operating point (<tt>wnom</tt>,<tt>dpnom</tt>, <tt>rhonom</tt>).
<li><tt>FFtype = FFtypes.Cfnom</tt>: the friction coefficient is computed by giving the (constant) value of the Fanning friction factor <tt>Cfnom</tt>.
<li><tt>FFtype = FFtypes.Colebrook</tt>: the Fanning friction factor is computed by Colebrook's equation (assuming Re > 2100, e.g. turbulent flow).
<li><tt>FFtype = FFtypes.NoFriction</tt>: no friction is assumed across the pipe.</ul>
<p>The dynamic momentum term is included or neglected depending on the <tt>DynamicMomentum</tt> parameter.
<p>If <tt>HydraulicCapacitance = HCtypes.Downstream</tt> (default option) then the compressibility effect depending on the pressure derivative is lumped at the outlet, while the optional dynamic momentum term depending on the flowrate is lumped at the inlet; therefore, the state variables are the outlet pressure and the inlet flowrate. If <tt>HydraulicCapacitance = HCtypes.Upstream</tt> the reverse takes place.
 If <tt>HydraulicCapacitance = HCtypes.Middle</tt>, the compressibility effect is lumped at the middle of the pipe; to use this option, an odd number of nodes N is required.
<p>Start values for the pressure and flowrate state variables are specified by <tt>pstart</tt>, <tt>wstart</tt>. The start values for the node enthalpies are linearly distributed from <tt>hstartin</tt> at the inlet to <tt>hstartout</tt> at the outlet.
<p>A bank of <tt>Nt</tt> identical tubes working in parallel can be modelled by setting <tt>Nt > 1</tt>. The geometric parameters always refer to a <i>single</i> tube.
<p>This models makes the temperature and external heat flow distributions available to connected components through the <tt>wall</tt> connector. If other variables (e.g. the heat transfer coefficient) are needed by external components to compute the actual heat flow, the <tt>wall</tt> connector can be replaced by an extended version of the <tt>DHT</tt> connector.
</HTML>", revisions="<html>
<ul>
<li><i>16 Sep 2005</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Option to lump compressibility at the middle added.</li>
<li><i>30 May 2005</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Initialisation support added.</li>
<li><i>24 Mar 2005</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       <tt>FFtypes</tt> package and <tt>NoFriction</tt> option added.</li>
<li><i>16 Dec 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Standard medium definition added.</li>
<li><i>8 Oct 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Model now based on <tt>Flow1DBase</tt>.
<li><i>24 Sep 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Removed <tt>wstart</tt>, <tt>pstart</tt>. Added <tt>pstartin</tt>, <tt>pstartout</tt>.
<li><i>22 Jun 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Adapted to Modelica.Media.
<li><i>15 Jan 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Computation of fluid velocity <i>u</i> added. Improved treatment of geometric parameters</li>.
<li><i>1 Oct 2003</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       First release.</li>
</ul>
</html>
"));
  end Flow1D;

  model Flow1DDB
    "1-dimensional fluid flow model for water or steam flow (finite volumes, Dittus-Boelter heat transfer)"
    extends Flow1D(redeclare Thermal.DHThtc wall);
    Medium.DynamicViscosity mu[N] "Dynamic viscosity";
    Medium.ThermalConductivity k[N] "Thermal conductivity";
    Medium.SpecificHeatCapacity cp[N] "Heat capacity at constant pressure";
  equation
    for j in 1:N loop
      // Additional fluid properties
      mu[j] = Medium.dynamicViscosity(fluidState[j]);
      k[j] = Medium.thermalConductivity(fluidState[j]);
      cp[j] = Medium.heatCapacity_cp(fluidState[j]);
      wall.gamma[j] = f_dittus_boelter(
          w,
          Dhyd,
          A,
          mu[j],
          k[j],
          cp[j]) "Heat transfer on the wall connector";
    end for;
    annotation (Documentation(info="<HTML>
<p>This model extends <tt>Flow1D</tt> by computing the distribution of the heat transfer coefficient <tt>gamma</tt> and making it available through an extended version of the <tt>wall</tt> connector.
<p>This model can be used in the case of one-phase water or steam flow. Dittus-Boelter's equation [1] is used to compute the heat transfer coefficient.
<p><b>References:</b></p>
<ol>
<li>J. C. Collier: <i>Convective Boiling and Condensation</i>, 2nd ed.,McGraw Hill, 1981, pp. 146.
</ol>
</HTML>", revisions="<html>
<ul>
<li><i>24 Mar 2005</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       <tt>FFtypes</tt> package and <tt>NoFriction</tt> option added.</li>
<li><i>16 Dec 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Standard medium definition added.</li>
<li><i>26 Jul 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Adapted to <tt>Modelica.Media</tt>.</li>
<li><i>20 Dec 2003</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Function call to <tt>f_dittus_boelter</tt> updated.</li>
<li><i>1 Oct 2003</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       First release.</li>
</ul>
</html>"));
  end Flow1DDB;

  model Flow1D2ph
    "1-dimensional fluid flow model for water/steam (finite volumes, 2-phase)"
    extends Modelica.Icons.ObsoleteModel;
    extends BaseClasses.Flow1DBase(redeclare replaceable package Medium =
          StandardWater "Medium model" constrainedby
        Modelica.Media.Interfaces.PartialTwoPhaseMedium,
        FluidPhaseStart=Choices.FluidPhase.FluidPhases.TwoPhases);
    replaceable ThermoPower.Thermal.DHT wall(N=N) annotation (Dialog(enable=
            false), Placement(transformation(extent={{-40,40},{40,60}},
            rotation=0)));
    import ThermoPower.Choices.Flow1D.FFtypes;
    import ThermoPower.Choices.Flow1D.HCtypes;
    // package SmoothMedium = Medium (final smoothModel=true);
    constant SI.Pressure pzero=10 "Small deltap for calculations";
    constant SI.Pressure pc=Medium.fluidConstants[1].criticalPressure;
    constant SI.SpecificEnthalpy hzero=1e-3 "Small value for deltah";
    // SmoothMedium.ThermodynamicState fluidState[N]
    //   "Thermodynamic state of the fluid at the nodes";
    Medium.ThermodynamicState fluidState[N]
      "Thermodynamic state of the fluid at the nodes";
    Medium.SaturationProperties sat "Properties of saturated fluid";
    SI.Length omega_hyd "Wet perimeter (single tube)";
    SI.Pressure Dpfric "Pressure drop due to friction";
    SI.Pressure Dpstat "Pressure drop due to static head";
    Real Kf[N - 1] "Friction coefficient";
    Real Kfl[N - 1] "Linear friction coefficient";
    Real Cf[N - 1] "Fanning friction factor";
    Real dwdt "Dynamic momentum term";
    Medium.AbsolutePressure p(start=pstart, stateSelect=StateSelect.prefer)
      "Fluid pressure for property calculations";
    SI.Pressure dpf[N - 1] "Pressure drop due to friction between two nodes";
    SI.MassFlowRate w(start=wnom/Nt) "Mass flowrate (single tube)";
    SI.MassFlowRate wbar[N - 1](each start=wnom/Nt);
    SI.Velocity u[N] "Fluid velocity";
    Medium.Temperature T[N] "Fluid temperature";
    Medium.Temperature Ts "Saturated water temperature";
    Medium.SpecificEnthalpy h[N](start=hstart) "Fluid specific enthalpy";
    Medium.SpecificEnthalpy htilde[N - 1](start=hstart[2:N],
                                          each stateSelect=StateSelect.prefer)
      "Enthalpy state variables";
    Medium.SpecificEnthalpy hl "Saturated liquid temperature";
    Medium.SpecificEnthalpy hv "Saturated vapour temperature";
    Real x[N] "Steam quality";
    Medium.Density rho[N] "Fluid density";
    Units.LiquidDensity rhol "Saturated liquid density";
    Units.GasDensity rhov "Saturated vapour density";
    SI.Mass M "Fluid mass";
    SI.Power Qj[N-1];  //DA CANCELLARE
  protected
    SI.DerEnthalpyByPressure dhldp
      "Derivative of saturated liquid enthalpy by pressure";
    SI.DerEnthalpyByPressure dhvdp
      "Derivative of saturated vapour enthalpy by pressure";
    SI.Density rhobar[N - 1] "Fluid average density";
    SI.DerDensityByPressure drdp[N] "Derivative of density by pressure";
    SI.DerDensityByPressure drbdp[N - 1]
      "Derivative of average density by pressure";
    SI.DerDensityByPressure drldp
      "Derivative of saturated liquid density by pressure";
    SI.DerDensityByPressure drvdp
      "Derivative of saturated vapour density by pressure";
    SI.SpecificVolume vbar[N - 1] "Average specific volume";
    SI.HeatFlux phibar[N - 1] "Average heat flux";
    SI.DerDensityByEnthalpy drdh[N] "Derivative of density by enthalpy";
    SI.DerDensityByEnthalpy drbdh1[N - 1]
      "Derivative of average density by left enthalpy";
    SI.DerDensityByEnthalpy drbdh2[N - 1]
      "Derivative of average density by right enthalpy";
    Real AA;
    Real AA1;
    Real dMdt[N - 1] "Derivative of fluid mass in each volume";
  equation
    //All equations are referred to a single tube
    omega_hyd = 4*A/Dhyd;
    // Friction factor selection
    for j in 1:(N - 1) loop
      if FFtype == FFtypes.Kfnom then
        Kf[j] = Kfnom*Kfc/(N - 1);
        Cf[j] = 2*Kf[j]*A^3/(omega_hyd*l);
      elseif FFtype == FFtypes.OpPoint then
        Kf[j] = dpnom*rhonom/(wnom/Nt)^2/(N - 1)*Kfc;
        Cf[j] = 2*Kf[j]*A^3/(omega_hyd*l);
      elseif FFtype == FFtypes.Cfnom then
        Kf[j] = Cfnom*omega_hyd*l/(2*A^3)*Kfc;
        Cf[j] = 2*Kf[j]*A^3/(omega_hyd*l);
      elseif FFtype == FFtypes.Colebrook then
        Cf[j] = if noEvent(htilde[j] < hl or htilde[j] > hv) then f_colebrook(
            w,
            Dhyd/A,
            e,
            Medium.dynamicViscosity(fluidState[j]))*Kfc else f_colebrook_2ph(
            w,
            Dhyd/A,
            e,
            Medium.dynamicViscosity(Medium.setBubbleState(sat, 1)),
            Medium.dynamicViscosity(Medium.setDewState(sat, 1)),
            x[j])*Kfc;
        Kf[j] = Cf[j]*omega_hyd*l/(2*A^3);
      elseif FFtype == FFtypes.NoFriction then
        Cf[j] = 0;
        Kf[j] = 0;
      else
        assert(FFtype <> FFtypes.NoFriction, "Unsupported FFtype");
        Cf[j] = 0;
        Kf[j] = 0;
      end if;
      assert(Kf[j] >= 0, "Negative friction coefficient");
      Kfl[j] = wnom/Nt*wnf*Kf[j];
    end for;

    // Dynamic momentum term
    if DynamicMomentum then
      dwdt = der(w);
    else
      dwdt = 0;
    end if;

    sum(dMdt) = (infl.m_flow/Nt + outfl.m_flow/Nt) "Mass balance";
    sum(dpf) = Dpfric "Total pressure drop due to friction";
    Dpstat = if abs(dzdx) < 1e-6 then 0 else g*l*dzdx*sum(rhobar)
      "Pressure drop due to static head";
    L/A*dwdt + (outfl.p - infl.p) + Dpstat + Dpfric = 0 "Momentum balance";
    for j in 1:(N - 1) loop
      A*l*rhobar[j]*der(htilde[j]) + wbar[j]*(h[j + 1] - h[j]) - A*l*der(p) = l
        *omega*phibar[j] "Energy balance";
      Qj[j] = l*omega*phibar[j];
      dMdt[j] = A*l*(drbdh1[j]*der(h[j]) + drbdh2[j]*der(h[j + 1]) + drbdp[j]*
        der(p)) "Mass balance for each volume";
      // Average volume quantities
      vbar[j] = 1/rhobar[j] "Average specific volume";
      wbar[j] = homotopy(infl.m_flow/Nt - sum(dMdt[1:j - 1]) - dMdt[j]/2, wnom/
        Nt);
      dpf[j] = (if FFtype == FFtypes.NoFriction then 0 else homotopy(smooth(1,
        Kf[j]*squareReg(w, wnom/Nt*wnf))*vbar[j], dpnom/(N - 1)/(wnom/Nt)*w));
      if avoidInletEnthalpyDerivative and j == 1 then
        // first volume properties computed by the outlet properties
        rhobar[j] = rho[j + 1];
        drbdp[j] = drdp[j + 1];
        drbdh1[j] = 0;
        drbdh2[j] = drdh[j + 1];
      elseif noEvent((h[j] < hl and h[j + 1] < hl) or (h[j] > hv and h[j + 1]
           > hv) or p >= (pc - pzero) or abs(h[j + 1] - h[j]) < hzero) then
        // 1-phase or almost uniform properties
        rhobar[j] = (rho[j] + rho[j + 1])/2;
        drbdp[j] = (drdp[j] + drdp[j + 1])/2;
        drbdh1[j] = drdh[j]/2;
        drbdh2[j] = drdh[j + 1]/2;
      elseif noEvent(h[j] >= hl and h[j] <= hv and h[j + 1] >= hl and h[j + 1]
           <= hv) then
        // 2-phase
        rhobar[j] = AA*log(rho[j]/rho[j + 1])/(h[j + 1] - h[j]);
        drbdp[j] = (AA1*log(rho[j]/rho[j + 1]) + AA*(1/rho[j]*drdp[j] - 1/rho[j
           + 1]*drdp[j + 1]))/(h[j + 1] - h[j]);
        drbdh1[j] = (rhobar[j] - rho[j])/(h[j + 1] - h[j]);
        drbdh2[j] = (rho[j + 1] - rhobar[j])/(h[j + 1] - h[j]);
      elseif noEvent(h[j] < hl and h[j + 1] >= hl and h[j + 1] <= hv) then
        // liquid/2-phase
        rhobar[j] = ((rho[j] + rhol)*(hl - h[j])/2 + AA*log(rhol/rho[j + 1]))/(
          h[j + 1] - h[j]);
        drbdp[j] = ((drdp[j] + drldp)*(hl - h[j])/2 + (rho[j] + rhol)/2*dhldp
           + AA1*log(rhol/rho[j + 1]) + AA*(1/rhol*drldp - 1/rho[j + 1]*drdp[j
           + 1]))/(h[j + 1] - h[j]);
        drbdh1[j] = (rhobar[j] - (rho[j] + rhol)/2 + drdh[j]*(hl - h[j])/2)/(h[
          j + 1] - h[j]);
        drbdh2[j] = (rho[j + 1] - rhobar[j])/(h[j + 1] - h[j]);
      elseif noEvent(h[j] >= hl and h[j] <= hv and h[j + 1] > hv) then
        // 2-phase/vapour
        rhobar[j] = (AA*log(rho[j]/rhov) + (rhov + rho[j + 1])*(h[j + 1] - hv)/
          2)/(h[j + 1] - h[j]);
        drbdp[j] = (AA1*log(rho[j]/rhov) + AA*(1/rho[j]*drdp[j] - 1/rhov*drvdp)
           + (drvdp + drdp[j + 1])*(h[j + 1] - hv)/2 - (rhov + rho[j + 1])/2*
          dhvdp)/(h[j + 1] - h[j]);
        drbdh1[j] = (rhobar[j] - rho[j])/(h[j + 1] - h[j]);
        drbdh2[j] = ((rhov + rho[j + 1])/2 - rhobar[j] + drdh[j + 1]*(h[j + 1]
           - hv)/2)/(h[j + 1] - h[j]);
      elseif noEvent(h[j] < hl and h[j + 1] > hv) then
        // liquid/2-phase/vapour
        rhobar[j] = ((rho[j] + rhol)*(hl - h[j])/2 + AA*log(rhol/rhov) + (rhov
           + rho[j + 1])*(h[j + 1] - hv)/2)/(h[j + 1] - h[j]);
        drbdp[j] = ((drdp[j] + drldp)*(hl - h[j])/2 + (rho[j] + rhol)/2*dhldp
           + AA1*log(rhol/rhov) + AA*(1/rhol*drldp - 1/rhov*drvdp) + (drvdp +
          drdp[j + 1])*(h[j + 1] - hv)/2 - (rhov + rho[j + 1])/2*dhvdp)/(h[j +
          1] - h[j]);
        drbdh1[j] = (rhobar[j] - (rho[j] + rhol)/2 + drdh[j]*(hl - h[j])/2)/(h[
          j + 1] - h[j]);
        drbdh2[j] = ((rhov + rho[j + 1])/2 - rhobar[j] + drdh[j + 1]*(h[j + 1]
           - hv)/2)/(h[j + 1] - h[j]);
      elseif noEvent(h[j] >= hl and h[j] <= hv and h[j + 1] < hl) then
        // 2-phase/liquid
        rhobar[j] = (AA*log(rho[j]/rhol) + (rhol + rho[j + 1])*(h[j + 1] - hl)/
          2)/(h[j + 1] - h[j]);
        drbdp[j] = (AA1*log(rho[j]/rhol) + AA*(1/rho[j]*drdp[j] - 1/rhol*drldp)
           + (drldp + drdp[j + 1])*(h[j + 1] - hl)/2 - (rhol + rho[j + 1])/2*
          dhldp)/(h[j + 1] - h[j]);
        drbdh1[j] = (rhobar[j] - rho[j])/(h[j + 1] - h[j]);
        drbdh2[j] = ((rhol + rho[j + 1])/2 - rhobar[j] + drdh[j + 1]*(h[j + 1]
           - hl)/2)/(h[j + 1] - h[j]);
      elseif noEvent(h[j] > hv and h[j + 1] < hl) then
        // vapour/2-phase/liquid
        rhobar[j] = ((rho[j] + rhov)*(hv - h[j])/2 + AA*log(rhov/rhol) + (rhol
           + rho[j + 1])*(h[j + 1] - hl)/2)/(h[j + 1] - h[j]);
        drbdp[j] = ((drdp[j] + drvdp)*(hv - h[j])/2 + (rho[j] + rhov)/2*dhvdp
           + AA1*log(rhov/rhol) + AA*(1/rhov*drvdp - 1/rhol*drldp) + (drldp +
          drdp[j + 1])*(h[j + 1] - hl)/2 - (rhol + rho[j + 1])/2*dhldp)/(h[j +
          1] - h[j]);
        drbdh1[j] = (rhobar[j] - (rho[j] + rhov)/2 + drdh[j]*(hv - h[j])/2)/(h[
          j + 1] - h[j]);
        drbdh2[j] = ((rhol + rho[j + 1])/2 - rhobar[j] + drdh[j + 1]*(h[j + 1]
           - hl)/2)/(h[j + 1] - h[j]);
      else
        // vapour/2-phase
        rhobar[j] = ((rho[j] + rhov)*(hv - h[j])/2 + AA*log(rhov/rho[j + 1]))/(
          h[j + 1] - h[j]);
        drbdp[j] = ((drdp[j] + drvdp)*(hv - h[j])/2 + (rho[j] + rhov)/2*dhvdp
           + AA1*log(rhov/rho[j + 1]) + AA*(1/rhov*drvdp - 1/rho[j + 1]*drdp[j
           + 1]))/(h[j + 1] - h[j]);
        drbdh1[j] = (rhobar[j] - (rho[j] + rhov)/2 + drdh[j]*(hv - h[j])/2)/(h[
          j + 1] - h[j]);
        drbdh2[j] = (rho[j + 1] - rhobar[j])/(h[j + 1] - h[j]);
      end if;
    end for;

    // Saturated fluid property calculations
    sat = Medium.setSat_p(p);
    Ts = sat.Tsat;
    rhol = Medium.bubbleDensity(sat);
    rhov = Medium.dewDensity(sat);
    hl = Medium.bubbleEnthalpy(sat);
    hv = Medium.dewEnthalpy(sat);
    drldp = Medium.dBubbleDensity_dPressure(sat);
    drvdp = Medium.dDewDensity_dPressure(sat);
    dhldp = Medium.dBubbleEnthalpy_dPressure(sat);
    dhvdp = Medium.dDewEnthalpy_dPressure(sat);
    AA = (hv - hl)/(1/rhov - 1/rhol);
    AA1 = ((dhvdp - dhldp)*(rhol - rhov)*rhol*rhov - (hv - hl)*(rhov^2*drldp -
      rhol^2*drvdp))/(rhol - rhov)^2;

    // Fluid property calculations
    for j in 1:N loop
      fluidState[j] = Medium.setState_phX(p, h[j]);
      T[j] = Medium.temperature(fluidState[j]);
      rho[j] = Medium.density(fluidState[j]);
      drdp[j] = Medium.density_derp_h(fluidState[j]);
      drdh[j] = Medium.density_derh_p(fluidState[j]);
      u[j] = w/(rho[j]*A);
      x[j] = noEvent(if h[j] <= hl then 0 else if h[j] >= hv then 1 else (h[j]
         - hl)/(hv - hl));
    end for;

    // Selection of representative pressure and flow rate variables
    if HydraulicCapacitance == HCtypes.Upstream then
      p = infl.p;
      w = -outfl.m_flow/Nt;
    else
      p = outfl.p;
      w = infl.m_flow/Nt;
    end if;

    // Boundary conditions
    infl.h_outflow = htilde[1];
    outfl.h_outflow = htilde[N - 1];
    h[1] = inStream(infl.h_outflow);
    h[2:N] = htilde;
    T = wall.T;
    phibar = (wall.phi[1:N - 1] + wall.phi[2:N])/2;

    Q = Nt*l*omega*sum(phibar) "Total heat flow through lateral boundary";
    M = sum(rhobar)*A*l "Fluid mass (single tube)";
    Tr = noEvent(M/max(infl.m_flow/Nt, Modelica.Constants.eps))
      "Residence time";

  initial equation
    if initOpt == Choices.Init.Options.noInit then
      // do nothing
    elseif initOpt == Choices.Init.Options.steadyState then
      der(htilde) = zeros(N - 1);
      if (not Medium.singleState) then
        der(p) = 0;
      end if;
    elseif initOpt == Choices.Init.Options.steadyStateNoP then
      der(htilde) = zeros(N - 1);
    elseif initOpt == Choices.Init.Options.steadyStateNoT and not Medium.singleState then
      der(p) = 0;
    else
      assert(false, "Unsupported initialisation option");
    end if;

    annotation (
      Diagram(graphics),
      Icon(graphics={Text(extent={{-100,-54},{100,-80}}, textString="%name")}),
      Documentation(info="<HTML>
<p>This model describes the flow of water or steam in a rigid tube. The basic modelling assumptions are:
<ul><li>The fluid state is either one-phase, or a two-phase mixture.
<li>In case of two-phase flow, the same velocity is assumed for both phases (homogeneous model).
<li>Uniform velocity is assumed on the cross section, leading to a 1-D distributed parameter model.
<li>Turbulent friction is always assumed; a small linear term is added to avoid numerical singularities at zero flowrate. The friction effects are not accurately computed in the laminar and transitional flow regimes, which however should not be an issue in most applications using water or steam as a working fluid.
<li>The model is based on dynamic mass, momentum, and energy balances. The dynamic momentum term can be switched off, to avoid the fast oscillations that can arise from its coupling with the mass balance (sound wave dynamics).
<li>The longitudinal heat diffusion term is neglected.
<li>The energy balance equation is written by assuming a uniform pressure distribution; the pressure drop is lumped either at the inlet or at the outlet.
<li>The fluid flow can exchange thermal power through the lateral surface, which is represented by the <tt>wall</tt> connector. The actual heat flux must be computed by a connected component (heat transfer computation module).
</ul>
<p>The mass, momentum, and energy balance equation are discretised with the finite volume method. The state variables are one pressure, one flowrate (optional) and N-1 specific enthalpies.
<p>The turbulent friction factor can be either assumed as a constant, or computed by Colebrook's equation. In the former case, the friction factor can be supplied directly, or given implicitly by a specified operating point. In any case, the multiplicative correction coefficient <tt>Kfc</tt> can be used to modify the friction coefficient, e.g. to fit experimental data.
<p>A small linear pressure drop is added to avoid numerical singularities at low or zero flowrate. The <tt>wnom</tt> parameter must be always specified: the additional linear pressure drop is such that it is equal to the turbulent pressure drop when the flowrate is equal to <tt>wnf*wnom</tt> (the default value is 1% of the nominal flowrate). Increase <tt>wnf</tt> if numerical instabilities occur in tubes with very low pressure drops.
<p>The model assumes that the mass flow rate is always from the inlet to the outlet. Small reverse flow is allowed (e.g. when closing a valve at the outlet), but the model will not account for it explicitly.
<p><b>Modelling options</b></p>
<p>Thermal variables (enthalpy, temperature, density) are computed in <tt>N</tt> equally spaced nodes, including the inlet (node 1) and the outlet (node N); <tt>N</tt> must be greater than or equal to 2.
<p>The dynamic momentum term is included or neglected depending on the <tt>DynamicMomentum</tt> parameter.
<p>The density is computed assuming a linear distribution of the specific
enthalpy between the nodes; this requires the availability of the time derivative of the inlet enthalpy. If this is not available, it is possible to set <tt>avoidInletEnthalpyDerivative</tt> to true, which will cause the mean density of the first volume to be approximated as its outlet density, thus avoiding the need of the inlet enthalpy derivative.
<p>The following options are available to specify the friction coefficient:
<ul><li><tt>FFtype = FFtypes.Kfnom</tt>: the hydraulic friction coefficient <tt>Kf</tt> is set directly to <tt>Kfnom</tt>.
<li><tt>FFtype = FFtypes.OpPoint</tt>: the hydraulic friction coefficient is specified by a nominal operating point (<tt>wnom</tt>,<tt>dpnom</tt>, <tt>rhonom</tt>).
<li><tt>FFtype = FFtypes.Cfnom</tt>: the friction coefficient is computed by giving the (constant) value of the Fanning friction factor <tt>Cfnom</tt>.
<li><tt>FFtype = FFtypes.Colebrook</tt>: the Fanning friction factor is computed by Colebrook's equation (assuming Re > 2100, e.g. turbulent flow).
<li><tt>FFtype = FFtypes.NoFriction</tt>: no friction is assumed across the pipe.</ul><p>If <tt>HydraulicCapacitance = 2</tt> (default option) then the mass storage term depending on the pressure is lumped at the outlet, while the optional momentum storage term depending on the flowrate is lumped at the inlet. If <tt>HydraulicCapacitance = 1</tt> the reverse takes place.
<p>Start values for pressure and flowrate are specified by <tt>pstart</tt>, <tt>wstart</tt>. The start values for the node enthalpies are linearly distributed from <tt>hstartin</tt> at the inlet to <tt>hstartout</tt> at the outlet.
<p>A bank of <tt>Nt</tt> identical tubes working in parallel can be modelled by setting <tt>Nt > 1</tt>. The geometric parameters always refer to a <i>single</i> tube.
<p>This models makes the temperature and external heat flow distributions visible through the <tt>wall</tt> connector. If other variables (e.g. the heat transfer coefficient) are needed by external components to compute the actual heat flow, the <tt>wall</tt> connector can be replaced by an extended version of the <tt>DHT</tt> connector.
</HTML>", revisions="<html>
<ul>
<li><i>27 Jul 2007</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Corrected error in the mass balance equation, which lead to loss/gain of
       mass during transients.</li>
<li><i>30 May 2005</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Initialisation support added.</li>
<li><i>24 Mar 2005</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       <tt>FFtypes</tt> package and <tt>NoFriction</tt> option added.</li>
<li><i>16 Dec 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Standard medium definition added.</li>
<li><i>8 Oct 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Model now based on <tt>Flow1DBase</tt>.
<li><i>24 Sep 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Removed <tt>wstart</tt>, <tt>pstart</tt>. Added <tt>pstartin</tt>, <tt>pstartout</tt>.
<li><i>28 Jul 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Adapted to <tt>Modelica.Media</tt>.
<li><i>15 Jan 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Computation of fluid velocity <i>u</i> added. Improved treatment of geometric parameters</li>
<li><i>1 Oct 2003</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       First release.</li>
</ul>
</html>"));
  end Flow1D2ph;

  model Flow1D2phDB
    "1-dimensional fluid flow model for 2-phase boiling flow (finite volumes, 2-phase, computation of heat transfer coeff.)"
    extends Flow1D2ph(redeclare Thermal.DHThtc wall);
    parameter SI.CoefficientOfHeatTransfer gamma_b=20000
      "Coefficient of heat transfer for boiling flow";
    parameter Real xCHF=0.9
      "Steam quality corresponding to the Critical Heat Flux";
    Medium.ThermodynamicState bubble "Bubble point state";
    Medium.ThermodynamicState dew "Dew point state";
  protected
    SI.CoefficientOfHeatTransfer gamma[N] "Raw heat transfer coefficient";
    SI.CoefficientOfHeatTransfer gamma_ls "H.t.c. just before bubble point";
    SI.CoefficientOfHeatTransfer gamma_chf "H.t.c. just after CHF";
    SI.CoefficientOfHeatTransfer gamma_corr_left[N]
      "Correction term to get smooth h.t.c.";
    SI.CoefficientOfHeatTransfer gamma_corr_right[N]
      "Correction term to get smooth h.t.c.";
    SI.SpecificEnthalpy hCHF "Enthalpy corresponding to the Critical Heat Flux";
    SI.DynamicViscosity mu_ls "Dynamic viscosity at bubble point";
    SI.DynamicViscosity mu_vs "Dynamic viscosity at dew point";
    SI.ThermalConductivity k_ls "Thermal conductivity at bubble point";
    SI.ThermalConductivity k_vs "Thermal conductivity at dew point";
    SI.SpecificHeatCapacity cp_ls "Specific heat capacity at bubble point";
    SI.SpecificHeatCapacity cp_vs "Specific heat capacity at dew point";
  equation
    hCHF = hl + xCHF*(hv - hl)
      "Specific enthalpy corresponding to critical heat flux";
    // Saturated fluid properties
    bubble = Medium.setBubbleState(sat, 1);
    dew = Medium.setDewState(sat, 1);
    mu_ls = Medium.dynamicViscosity(bubble);
    k_ls = Medium.thermalConductivity(bubble);
    cp_ls = Medium.heatCapacity_cp(bubble);
    mu_vs = Medium.dynamicViscosity(dew);
    k_vs = Medium.thermalConductivity(dew);
    cp_vs = Medium.heatCapacity_cp(dew);
    // H.t.c. just outside the nucleate boiling region
    gamma_ls = f_dittus_boelter(
        w,
        Dhyd,
        A,
        mu_ls,
        k_ls,
        cp_ls);
    gamma_chf = f_dittus_boelter(
        w*xCHF,
        Dhyd,
        A,
        mu_vs,
        k_vs,
        cp_vs);

    // Nodal h.t.c.
    for j in 1:N loop
      // a) Subcooled liquid
      // b) Wet steam after dryout: Dittus-Boelter's correlation considering
      //    only the vapour phase
      // c) Nucleate boiling: constant h.t.c.
      gamma[j] = noEvent(if h[j] < hl or h[j] > hv then f_dittus_boelter(
          w,
          Dhyd,
          A,
          Medium.dynamicViscosity(fluidState[j]),
          Medium.thermalConductivity(fluidState[j]),
          Medium.heatCapacity_cp(fluidState[j])) else if h[j] > hCHF then
        f_dittus_boelter(
          w*x[j],
          Dhyd,
          A,
          mu_vs,
          k_vs,
          cp_vs) else gamma_b);
    end for;

    // Corrections due to boundaries near the nodes to the left
    // to achieve continuous h.t.c.
    gamma_corr_left[1] = 0;
    for j in 2:N loop
      gamma_corr_left[j] = noEvent(if h[j] < hl then (if (h[j - 1] + h[j])/2 >
        hl then ((h[j - 1] - hl)/(h[j - 1] - h[j]) - 0.5)*(gamma_b - gamma_ls)*
        (if j == N then 2 else 1) else 0) else if h[j] > hCHF then (if (h[j - 1]
         + h[j])/2 < hCHF then ((hCHF - h[j - 1])/(h[j] - h[j - 1]) - 0.5)*(
        gamma_b - gamma_chf)*(if j == N then 2 else 1) else 0) else if (h[j - 1]
         + h[j])/2 < hl then ((hl - h[j - 1])/(h[j] - h[j - 1]) - 0.5)*(
        gamma_ls - gamma_b)*(if j == N then 2 else 1) else if (h[j - 1] + h[j])
        /2 > hCHF then ((h[j - 1] - hCHF)/(h[j - 1] - h[j]) - 0.5)*(gamma_chf
         - gamma_b)*(if j == N then 2 else 1) else 0);
    end for;

    // Corrections due to boundaries near the nodes to the right
    // to achieve continuous h.t.c.
    gamma_corr_right[N] = 0;
    for j in 1:N - 1 loop
      gamma_corr_right[j] = noEvent(if h[j] < hl then (if (h[j + 1] + h[j])/2
         > hl then ((h[j + 1] - hl)/(h[j + 1] - h[j]) - 0.5)*(gamma_b -
        gamma_ls)*(if j == 1 then 2 else 1) else 0) else if h[j] > hCHF then (
        if (h[j + 1] + h[j])/2 < hCHF then ((hCHF - h[j + 1])/(h[j] - h[j + 1])
         - 0.5)*(gamma_b - gamma_chf)*(if j == 1 then 2 else 1) else 0) else
        if (h[j + 1] + h[j])/2 < hl then ((hl - h[j + 1])/(h[j] - h[j + 1]) -
        0.5)*(gamma_ls - gamma_b)*(if j == 1 then 2 else 1) else if (h[j + 1]
         + h[j])/2 > hCHF then ((h[j + 1] - hCHF)/(h[j + 1] - h[j]) - 0.5)*(
        gamma_chf - gamma_b)*(if j == 1 then 2 else 1) else 0);
    end for;

    wall.gamma = gamma + gamma_corr_left + gamma_corr_right
      "H.t.c. including smoothing terms";
    annotation (Documentation(info="<HTML>
<p>This model extends <tt>Flow1D2ph</tt> by computing the distribution of the heat transfer coefficient <tt>gamma</tt> and making it available through an extended version of the <tt>wall</tt> connector.
<p>This simplified model can be used for one-phase or two-phase water/steam flow. The heat transfer coefficient is computed according to the following hypotheses:
<ul>
<li> If the fluid is subcooled liquid or superheated steam, Dittus-Boelter's correlation [1] is used.
<li> If the fluid is a two-phase mixture with a steam fraction less than the (constant) critical value <tt>xCHF</tt>, boiling heat transfer is assumed with a heat transfer coefficient equal to <tt>gamma_b</tt>.
<li> If the fluid is wet steam with a steam fraction greater than the (constant) critical value <tt>xCHF</tt>, the heat transfer coefficient is computed according to Dittus-Boelter's correlation, by considering only the steam fraction of the mixture.
</ul>
<p>A smoothing algorithm is applied to the nodes which are in the neighbourhood of a transition boundary between non-boiling and boiling conditions, to avoid non-physical sudden changes of the nodal values of the heat transfer coefficient when the transition boundary passes through a node. The computed values of the heat transfer coefficient are thus a continuous function of the nodal enthalpies and pressures, so that it is not necessary to generate events in order to handle discontinuities
<p><b>References</b></p>
<ol>
<li>J. C. Collier: <i>Convective Boiling and Condensation</i>, 2nd ed.,McGraw Hill, 1981, pp. 146.
</ol>
</HTML>", revisions="<html>
<ul>
<li><i>24 Mar 2005</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       <tt>FFtypes</tt> package and <tt>NoFriction</tt> option added.</li>
<li><i>16 Dec 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Standard medium definition added.</li>
<li><i>1 Nov 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Equations revisited.</li>
<li><i>24 Sep 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Adapted to Modelica.Media.</li>
<li><i>11 Feb 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Computation of the h.t.c. extended to all the thermodynamic conditions of the fluid.</li>
<li><i>1 Oct 2003</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       First release.</li>
</ul>
</html>"));
  end Flow1D2phDB;

  model Flow1D2phChen
    "1-dimensional fluid flow model for 2-phase boiling flow (finite volumes, 2-phase, Chen correlation)"
    extends Flow1D2ph(redeclare Thermal.DHThtc wall);
    parameter Real xCHF=0.9 "Steam quality corresponding to Critical Heat Flux";
    Medium.ThermodynamicState bubble "Bubble point state";
    Medium.ThermodynamicState dew "Dew point state";
  protected
    SI.CoefficientOfHeatTransfer gamma[N] "Raw heat transfer coefficient";
    SI.CoefficientOfHeatTransfer gamma_ls "H.t.c. just before bubble point";
    SI.CoefficientOfHeatTransfer gamma_chf "H.t.c. just after CHF";
    SI.CoefficientOfHeatTransfer gamma_corr_left[N]
      "Correction term to get smooth h.t.c.";
    SI.CoefficientOfHeatTransfer gamma_corr_right[N]
      "Correction term to get smooth h.t.c.";
    Medium.SpecificEnthalpy hCHF
      "Enthalpy corresponding to the Critical Heat Flux";
    Medium.DynamicViscosity mu_ls "Dynamic viscosity at bubble point";
    Medium.DynamicViscosity mu_vs "Dynamic viscosity at dew point";
    Medium.ThermalConductivity k_ls "Thermal conductivity at bubble point";
    Medium.ThermalConductivity k_vs "Thermal conductivity at dew point";
    Medium.SpecificHeatCapacity cp_ls "Specific heat capacity at bubble point";
    Medium.SpecificHeatCapacity cp_vs "Specific heat capacity at dew point";
    Medium.SurfaceTension sigma "Surface tension";
  equation
    hCHF = hl + xCHF*(hv - hl)
      "Specific enthalpy corresponding to critical heat flux";
    // Saturated water and steam properties
    bubble = Medium.setBubbleState(sat, 1);
    dew = Medium.setDewState(sat, 1);
    mu_ls = Medium.dynamicViscosity(bubble);
    k_ls = Medium.thermalConductivity(bubble);
    cp_ls = Medium.heatCapacity_cp(bubble);
    mu_vs = Medium.dynamicViscosity(dew);
    k_vs = Medium.thermalConductivity(dew);
    cp_vs = Medium.heatCapacity_cp(dew);
    sigma = Medium.surfaceTension(sat);
    // H.t.c. just outside the nucleate boiling region
    gamma_ls = f_dittus_boelter(
        w,
        Dhyd,
        A,
        mu_ls,
        k_ls,
        cp_ls);
    gamma_chf = f_dittus_boelter(
        w*xCHF,
        Dhyd,
        A,
        mu_vs,
        k_vs,
        cp_vs);

    // Nodal h.t.c. computations
    for j in 1:N loop
      // a) Subcooled liquid
      // b) Wet steam after dryout: Dittus-Boelter's correlation considering
      //    only the vapour phase
      // c) Nucleate boiling: constant h.t.c.
      gamma[j] = noEvent(if h[j] < hl or h[j] > hv then f_dittus_boelter(
          w,
          Dhyd,
          A,
          Medium.dynamicViscosity(fluidState[j]),
          Medium.thermalConductivity(fluidState[j]),
          Medium.heatCapacity_cp(fluidState[j])) else if h[j] > hCHF then
        f_dittus_boelter(
          w*x[j],
          Dhyd,
          A,
          mu_vs,
          k_vs,
          cp_vs) else f_chen(
          w,
          Dhyd,
          A,
          mu_ls,
          k_ls,
          cp_ls,
          rhol,
          sigma,
          rhov,
          mu_vs,
          wall.T[j] - Medium.saturationTemperature(p),
          Medium.saturationPressure(wall.T[j]) - p,
          hv - hl,
          x[j]));
    end for;

    // Corrections due to boundaries near the nodes to the left
    // to achieve continuous h.t.c.
    gamma_corr_left[1] = 0;
    for j in 2:N loop
      gamma_corr_left[j] = noEvent(if h[j] < hl then (if (h[j - 1] + h[j])/2 >
        hl then ((h[j - 1] - hl)/(h[j - 1] - h[j]) - 0.5)*(f_chen(
          w,
          Dhyd,
          A,
          mu_ls,
          k_ls,
          cp_ls,
          rhol,
          sigma,
          rhov,
          mu_vs,
          wall.T[j] - Medium.saturationTemperature(p),
          Medium.saturationPressure(wall.T[j]) - p,
          hv - hl,
          0) - gamma_ls)*(if j == N then 2 else 1) else 0) else if h[j] > hCHF
         then (if (h[j - 1] + h[j])/2 < hCHF then ((hCHF - h[j - 1])/(h[j] - h[
        j - 1]) - 0.5)*(f_chen(
          w,
          Dhyd,
          A,
          mu_ls,
          k_ls,
          cp_ls,
          rhol,
          sigma,
          rhov,
          mu_vs,
          wall.T[j] - Medium.saturationTemperature(p),
          Medium.saturationPressure(wall.T[j]) - p,
          hv - hl,
          xCHF) - gamma_chf)*(if j == N then 2 else 1) else 0) else if (h[j - 1]
         + h[j])/2 < hl then ((hl - h[j - 1])/(h[j] - h[j - 1]) - 0.5)*(
        gamma_ls - f_chen(
          w,
          Dhyd,
          A,
          mu_ls,
          k_ls,
          cp_ls,
          rhol,
          sigma,
          rhov,
          mu_vs,
          wall.T[j] - Medium.saturationTemperature(p),
          Medium.saturationPressure(wall.T[j]) - p,
          hv - hl,
          0))*(if j == N then 2 else 1) else if (h[j - 1] + h[j])/2 > hCHF
         then ((h[j - 1] - hCHF)/(h[j - 1] - h[j]) - 0.5)*(gamma_chf - f_chen(
          w,
          Dhyd,
          A,
          mu_ls,
          k_ls,
          cp_ls,
          rhol,
          sigma,
          rhov,
          mu_vs,
          wall.T[j] - Medium.saturationTemperature(p),
          Medium.saturationPressure(wall.T[j]) - p,
          hv - hl,
          xCHF))*(if j == N then 2 else 1) else 0);
    end for;

    // Compute corrections due to boundaries near the nodes to the right
    // to achieve continuous h.t.c.
    gamma_corr_right[N] = 0;
    for j in 1:N - 1 loop
      gamma_corr_right[j] = noEvent(if h[j] < hl then (if (h[j + 1] + h[j])/2
         > hl then ((h[j + 1] - hl)/(h[j + 1] - h[j]) - 0.5)*(f_chen(
          w,
          Dhyd,
          A,
          mu_ls,
          k_ls,
          cp_ls,
          rhol,
          sigma,
          rhov,
          mu_vs,
          wall.T[j] - Medium.saturationTemperature(p),
          Medium.saturationPressure(wall.T[j]) - p,
          hv - hl,
          0) - gamma_ls)*(if j == 1 then 2 else 1) else 0) else if h[j] > hCHF
         then (if (h[j + 1] + h[j])/2 < hCHF then ((hCHF - h[j + 1])/(h[j] - h[
        j + 1]) - 0.5)*(f_chen(
          w,
          Dhyd,
          A,
          mu_ls,
          k_ls,
          cp_ls,
          rhol,
          sigma,
          rhov,
          mu_vs,
          wall.T[j] - Medium.saturationTemperature(p),
          Medium.saturationPressure(wall.T[j]) - p,
          hv - hl,
          xCHF) - gamma_chf)*(if j == 1 then 2 else 1) else 0) else if (h[j + 1]
         + h[j])/2 < hl then ((hl - h[j + 1])/(h[j] - h[j + 1]) - 0.5)*(
        gamma_ls - f_chen(
          w,
          Dhyd,
          A,
          mu_ls,
          k_ls,
          cp_ls,
          rhol,
          sigma,
          rhov,
          mu_vs,
          wall.T[j] - Medium.saturationTemperature(p),
          Medium.saturationPressure(wall.T[j]) - p,
          hv - hl,
          0))*(if j == 1 then 2 else 1) else if (h[j + 1] + h[j])/2 > hCHF
         then ((h[j + 1] - hCHF)/(h[j + 1] - h[j]) - 0.5)*(gamma_chf - f_chen(
          w,
          Dhyd,
          A,
          mu_ls,
          k_ls,
          cp_ls,
          rhol,
          sigma,
          rhov,
          mu_vs,
          wall.T[j] - Medium.saturationTemperature(p),
          Medium.saturationPressure(wall.T[j]) - p,
          hv - hl,
          xCHF))*(if j == 1 then 2 else 1) else 0);
    end for;

    wall.gamma = gamma + gamma_corr_left + gamma_corr_right
      "H.t.c. including smoothing terms";
    annotation (Documentation(info="<HTML>
<p>This model extends <tt>Flow1D2ph</tt> by computing the distribution of the heat transfer coefficient <tt>gamma</tt> and making it available through an extended version of the <tt>wall</tt> connector.
<p>The model can be used for one-phase or two-phase water/steam flow. The heat transfer coefficient is computed according to the following hypotheses:
<ul>
<li> If the fluid is subcooled liquid or superheated steam, Dittus-Boelter's correlation [1] is used.
<li> If the fluid is a two-phase mixture with a steam fraction less than the (constant) critical value <tt>xCHF</tt>, the heat transfer coefficient is computed according to Chen's correlation [2].
<li> If the fluid is wet steam with a steam fraction greater than the (constant) critical value <tt>xCHF</tt>, the heat transfer coefficient is computed according to Dittus-Boelter's correlation [1], by considering only the steam fraction of the mixture.
</ul>
<p>A smoothing algorithm is applied to the nodes which are in the neighbourhood of a transition boundary between non-boiling and boiling conditions, to avoid non-physical sudden changes of the nodal values of the heat transfer coefficient when the transition boundary passes through a node. The computed values of the heat transfer coefficient are thus a continuous function of the nodal enthalpies and pressures, so that it is not necessary to generate events in order to handle discontinuities
<p><b>References</b></p>
<ol>
<li>J. C. Collier: <i>Convective Boiling and Condensation</i>, 2nd ed.,McGraw Hill, 1981, pp. 146.
</ol>
<ol>
<li>J. C. Collier: <i>Convective Boiling and Condensation</i>, 2nd ed.,McGraw Hill, 1981, pp. 215-220.
</ol>
<p><b>Revision history:</b></p>
</HTML>", revisions="<html>
<ul>
<li><i>24 Mar 2005</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       <tt>FFtypes</tt> package and <tt>NoFriction</tt> option added.</li>
<li><i>16 Dec 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Standard medium definition added.</li>
<li><i>1 Nov 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Equations revisited.</li>
<li><i>24 Sep 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Adapted to Modelica.Media.</li>
<li><i>11 Feb 2004</i>
       First release.</li>
</ul>
</html>"));
  end Flow1D2phChen;

  model Flow1Dfem
    "1-dimensional fluid flow model for water/steam (finite elements)"
    extends Modelica.Icons.ObsoleteModel;
    extends BaseClasses.Flow1DBase;
    replaceable ThermoPower.Thermal.DHT wall(N=N) annotation (Dialog(enable=
            false), Placement(transformation(extent={{-40,40},{40,60}},
            rotation=0)));
    import Modelica.Math.*;
    import ThermoPower.Choices.Flow1D.FFtypes;
    import ThermoPower.Choices.Flow1D.HCtypes;
    Medium.ThermodynamicState fluidState[N]
      "Thermodynamic state of the fluid at the nodes";
    parameter Real alpha(
      min=0,
      max=1) = 1 "Numerical stabilization coefficient";
    parameter Real ML(
      min=0,
      max=1) = 0 "Mass Lumping Coefficient";
    parameter Real wnf_bc=0.01
      "Fraction of the nominal total mass flow rate for FEM regularization";
    parameter Boolean regularizeBoundaryConditions = false
      "Regularize boundary condition matrices";
    parameter Boolean idealGasDensityDistribution = false
      "Assume ideal-gas-type density distributions for mass balances";
    constant Real g=Modelica.Constants.g_n;
    final parameter Boolean evenN=(div(N, 2)*2 == N)
      "The number of nodes is even";
    SI.Length omega_hyd "Hydraulic perimeter (single tube)";
    Real Kf[N] "Friction coefficients";
    Real Cf[N] "Fanning friction factors";
    Real dwdt "Dynamic momentum term";
    Medium.AbsolutePressure p(start=pstart) "Fluid pressure";
    SI.Pressure Dpfric "Pressure drop due to friction (total)";
    SI.Pressure Dpfric1
      "Pressure drop due to friction (from inlet to capacitance)";
    SI.Pressure Dpfric2
      "Pressure drop due to friction (from capacitance to outlet)";
    SI.Pressure Dpstat "Pressure drop due to static head";
    SI.MassFlowRate w[N](each start=wnom/Nt) "Mass flowrate (single tube)";
    SI.Velocity u[N] "Fluid velocity";
    SI.HeatFlux phi[N] "External heat flux";
    Medium.Temperature T[N] "Fluid temperature";
    Medium.SpecificEnthalpy h[N](start=hstart) "Fluid specific enthalpy";
    Medium.Density rho[N] "Fluid density";
    SI.SpecificVolume v[N] "Fluid specific volume";
    SI.Mass Mtot "Total mass of fluid";
  protected
    SI.DerDensityByEnthalpy drdh[N] "Derivative of density by enthalpy";
    SI.DerDensityByPressure drdp[N] "Derivative of density by pressure";
    Real dvdt[N] "Time derivatives of specific volume";

    Real Y[N, N];
    Real M[N, N];
    Real D[N];
    Real D1[N];
    Real D2[N];
    Real G[N];
    Real B[N, N];
    Real C[N, N];
    Real K[N, N];

    Real alpha_sgn;

    Real YY[N, N];

  equation
    //All equations are referred to a single tube

    // Selection of representative pressure variable
    if HydraulicCapacitance == HCtypes.Middle then
      p = infl.p - Dpfric1 - Dpstat/2;
    elseif HydraulicCapacitance == HCtypes.Upstream then
      p = infl.p;
    elseif HydraulicCapacitance == HCtypes.Downstream then
      p = outfl.p;
    else
      assert(false, "Unsupported HydraulicCapacitance option");
    end if;

    //Friction factor selection
    omega_hyd = 4*A/Dhyd;
    for i in 1:N loop
      if FFtype == FFtypes.Kfnom then
        Kf[i] = Kfnom*Kfc;
      elseif FFtype == FFtypes.OpPoint then
        Kf[i] = dpnom*rhonom/(wnom/Nt)^2*Kfc;
      elseif FFtype == FFtypes.Cfnom then
        Cf[i] = Cfnom*Kfc;
      elseif FFtype == FFtypes.Colebrook then
        Cf[i] = f_colebrook(
            w[i],
            Dhyd/A,
            e,
            Medium.dynamicViscosity(fluidState[i]))*Kfc;
      elseif FFtype == FFtypes.NoFriction then
        Cf[i] = 0;
      end if;
      assert(Kf[i] >= 0, "Negative friction coefficient");
      Kf[i] = Cf[i]*omega_hyd*L/(2*A^3)
        "Relationship between friction coefficient and Fanning friction factor";
    end for;

    //Dynamic Momentum [not] accounted for
    if DynamicMomentum then
      if HydraulicCapacitance == HCtypes.Upstream then
        dwdt = der(w[N]);
      elseif HydraulicCapacitance == HCtypes.Downstream then
        dwdt = der(w[1]);
      else
        assert(false,
          "DynamicMomentum == true requires either Upstream or Downstream capacitance");
      end if;
    else
      dwdt = 0;
    end if;

    L/A*dwdt + (outfl.p - infl.p) + Dpstat + Dpfric = 0
      "Momentum balance equation";

    w[1] = infl.m_flow/Nt "Inlet flow rate - single tube";
    w[N] = -outfl.m_flow/Nt "Outlet flow rate - single tube";

    Dpfric = Dpfric1 + Dpfric2 "Total pressure drop due to friction";

    if FFtype == FFtypes.NoFriction then
      Dpfric1 = 0;
      Dpfric2 = 0;
    else
      Dpfric1 = homotopy(sum(Kf[i]/L*squareReg(w[i], wnom/Nt*wnf)*D1[i]/rho[i]
        for i in 1:N), dpnom/2/(wnom/Nt)*w[1])
        "Pressure drop from inlet to capacitance";
      Dpfric2 = homotopy(sum(Kf[i]/L*squareReg(w[i], wnom/Nt*wnf)*D2[i]/rho[i]
        for i in 1:N), dpnom/2/(wnom/Nt)*w[N])
        "Pressure drop from capacitance to outlet";
    end if "Pressure drop due to friction";

    Dpstat = if abs(dzdx) < 1e-6 then 0 else g*dzdx*rho*D
      "Pressure drop due to static head";
    ((1 - ML)*Y + ML*YY)*der(h) + B/A*h + C*h/A = der(p)*G + M*(omega/A)*phi +
      K*w/A "Energy balance equation";

    // Fluid property calculations
    for j in 1:N loop
      fluidState[j] = Medium.setState_phX(p, h[j]);
      T[j] = Medium.temperature(fluidState[j]);
      rho[j] = Medium.density(fluidState[j]);
      drdp[j] = if Medium.singleState then 0 else Medium.density_derp_h(
        fluidState[j]);
      drdh[j] = Medium.density_derh_p(fluidState[j]);
      dvdt[j] = -1/rho[j]^2*(drdp[j]*der(p) + drdh[j]*der(h[j]));
      v[j] = 1/rho[j];
      u[j] = w[j]/(rho[j]*A);
    end for;

    //Wall energy flux and  temperature
    T = wall.T;
    phi = wall.phi;

    //Boundary Values of outflowing fluid enthalpies
    h[1] = infl.h_outflow;
    h[N] = outfl.h_outflow;

    alpha_sgn = alpha*sign(infl.m_flow - outfl.m_flow);

    for i in 1:N - 1 loop
      if idealGasDensityDistribution then
        (w[i + 1] - w[i]) = noEvent(
          if abs((v[i+1]-v[i])/v[i]) < 1e-7 then
             2*A*l/(v[i]+v[i+1])^2*(dvdt[i]+dvdt[i+1])
          else
             -A*l/(v[i+1]-v[i])*(
              (dvdt[i+1]*v[i]-dvdt[i]*v[i+1])/(v[i+1]*v[i]) -
              (dvdt[i+1]-dvdt[i])/(v[i+1]-v[i])*log(v[i+1]/v[i])));
      else
      (w[i + 1] - w[i]) = -A*l*(
        der(p)*1/2*(drdp[i + 1] + drdp[i]) +
        1/6*(der(h[i])*(2*drdh[i] + drdh[i + 1]) +
             der(h[i + 1])*(drdh[i] + 2*drdh[i + 1]))) "Mass balance equations";
      end if;
    end for;

    // Energy equation FEM matrices
    Y[1, 1] = rho[1]*((-l/12)*(2*alpha_sgn - 3)) + rho[2]*((-l/12)*(alpha_sgn
       - 1));
    Y[1, 2] = rho[1]*((-l/12)*(alpha_sgn - 1)) + rho[2]*((-l/12)*(2*alpha_sgn
       - 1));
    Y[N, N] = rho[N - 1]*((l/12)*(alpha_sgn + 1)) + rho[N]*((l/12)*(2*alpha_sgn
       + 3));
    Y[N, N - 1] = rho[N - 1]*((l/12)*(2*alpha_sgn + 1)) + rho[N]*((l/12)*(
      alpha_sgn + 1));
    if N > 2 then
      for i in 2:N - 1 loop
        Y[i, i - 1] = rho[i - 1]*((l/12)*(2*alpha_sgn + 1)) + rho[i]*((l/12)*(
          alpha_sgn + 1));
        Y[i, i] = rho[i - 1]*((l/12)*(alpha_sgn + 1)) + rho[i]*(l/2) + rho[i +
          1]*(-(l/12)*(alpha_sgn - 1));
        Y[i, i + 1] = rho[i]*((-l/12)*(alpha_sgn - 1)) + rho[i + 1]*((-l/12)*(2
          *alpha_sgn - 1));
        Y[1, i + 1] = 0;
        Y[N, i - 1] = 0;
        for j in 1:(i - 2) loop
          Y[i, j] = 0;
        end for;
        for j in (i + 2):N loop
          Y[i, j] = 0;
        end for;
      end for;
    end if;

    for i in 1:N loop
      for j in 1:N loop
        YY[i, j] = if (i <> j) then 0 else sum(Y[:, j]);
      end for;
    end for;

    M[1, 1] = l/3 - l*alpha_sgn/4;
    M[N, N] = l/3 + l*alpha_sgn/4;
    M[1, 2] = l/6 - l*alpha_sgn/4;
    M[N, (N - 1)] = l/6 + l*alpha_sgn/4;
    if N > 2 then
      for i in 2:N - 1 loop
        M[i, i - 1] = l/6 + l*alpha_sgn/4;
        M[i, i] = 2*l/3;
        M[i, i + 1] = l/6 - l*alpha_sgn/4;
        M[1, i + 1] = 0;
        M[N, i - 1] = 0;
        for j in 1:(i - 2) loop
          M[i, j] = 0;
        end for;
        for j in (i + 2):N loop
          M[i, j] = 0;
        end for;
      end for;
    end if;

    B[1, 1] = (-1/3 + alpha_sgn/4)*w[1] + (-1/6 + alpha_sgn/4)*w[2];
    B[1, 2] = (1/3 - alpha_sgn/4)*w[1] + (1/6 - alpha_sgn/4)*w[2];
    B[N, N] = (1/6 + alpha_sgn/4)*w[N - 1] + (1/3 + alpha_sgn/4)*w[N];
    B[N, N - 1] = (-1/(6) - alpha_sgn/4)*w[N - 1] + (-1/3 - alpha_sgn/4)*w[N];
    if N > 2 then
      for i in 2:N - 1 loop
        B[i, i - 1] = (-1/6 - alpha_sgn/4)*w[i - 1] + (-1/3 - alpha_sgn/4)*w[i];
        B[i, i] = (1/6 + alpha_sgn/4)*w[i - 1] + (alpha_sgn/2)*w[i] + (-1/6 +
          alpha_sgn/4)*w[i + 1];
        B[i, i + 1] = (1/3 - alpha_sgn/4)*w[i] + (1/6 - alpha_sgn/4)*w[i + 1];
        B[1, i + 1] = 0;
        B[N, i - 1] = 0;
        for j in 1:(i - 2) loop
          B[i, j] = 0;
        end for;
        for j in (i + 2):N loop
          B[i, j] = 0;
        end for;
      end for;
    end if;

    if Medium.singleState then
      G = zeros(N) "No influence of pressure";
    else
      G[1] = l/2*(1 - alpha_sgn);
      G[N] = l/2*(1 + alpha_sgn);
      if N > 2 then
        for i in 2:N - 1 loop
          G[i] = l;
        end for;
      end if;
    end if;

    // boundary condition matrices
    if regularizeBoundaryConditions then
      C[1, 1] = Functions.stepReg(
        infl.m_flow - wnom*wnf_bc,
        (1 - alpha_sgn/2)*w[1],
        0,
        wnom*wnf_bc);
      C[N, N] = Functions.stepReg(
        outfl.m_flow - wnom*wnf_bc,
        -(1 + alpha_sgn/2)*w[N],
        0,
        wnom*wnf_bc);
    else
      C[1, 1] = noEvent(if infl.m_flow >= 0 then (1 - alpha_sgn/2)*w[1] else 0);
      C[N, N] = noEvent(if outfl.m_flow >= 0 then -(1 + alpha_sgn/2)*w[N] else 0);
    end if;
    C[N, 1] = 0;
    C[1, N] = 0;
    if (N > 2) then
      for i in 2:(N - 1) loop
        C[1, i] = 0;
        C[N, i] = 0;
        for j in 1:N loop
          C[i, j] = 0;
        end for;
      end for;
    end if;

    if regularizeBoundaryConditions then
      K[1, 1] = Functions.stepReg(
        infl.m_flow - wnom*wnf_bc,
        (1 - alpha_sgn/2)*inStream(infl.h_outflow),
        0,
        wnom*wnf_bc);
      K[N, N] = Functions.stepReg(
        outfl.m_flow - wnom*wnf_bc,
        -(1 + alpha_sgn/2)*inStream(outfl.h_outflow),
        0,
        wnom*wnf_bc);
    else
      K[1, 1] = noEvent(if infl.m_flow >= 0 then (1 - alpha_sgn/2)*inStream(infl.h_outflow) else 0);
      K[N, N] = noEvent(if outfl.m_flow >= 0 then -(1 + alpha_sgn/2)*inStream(outfl.h_outflow) else 0);
    end if;

    K[N, 1] = 0;
    K[1, N] = 0;
    if (N > 2) then
      for i in 2:(N - 1) loop
        K[1, i] = 0;
        K[N, i] = 0;
        for j in 1:N loop
          K[i, j] = 0;
        end for;
      end for;
    end if;

    // Momentum and Mass balance equation matrices
    D[1] = l/2;
    D[N] = l/2;
    for i in 2:N - 1 loop
      D[i] = l;
    end for;
    if HydraulicCapacitance == HCtypes.Middle then
      D1 = l*(if N == 2 then {3/8,1/8} else if evenN then cat(
          1,
          {1/2},
          ones(max(0, div(N, 2) - 2)),
          {7/8,1/8},
          zeros(div(N, 2) - 1)) else cat(
          1,
          {1/2},
          ones(div(N, 2) - 1),
          {1/2},
          zeros(div(N, 2))));
      D2 = l*(if N == 2 then {1/8,3/8} else if evenN then cat(
          1,
          zeros(div(N, 2) - 1),
          {1/8,7/8},
          ones(max(div(N, 2) - 2, 0)),
          {1/2}) else cat(
          1,
          zeros(div(N, 2)),
          {1/2},
          ones(div(N, 2) - 1),
          {1/2}));
    elseif HydraulicCapacitance == HCtypes.Upstream then
      D1 = zeros(N);
      D2 = D;
    elseif HydraulicCapacitance == HCtypes.Downstream then
      D1 = D;
      D2 = zeros(N);
    else
      assert(false, "Unsupported HydraulicCapacitance option");
    end if;

    Q = Nt*omega*D*phi "Total heat flow through lateral boundary";
    Mtot = Nt*D*rho*A "Total mass of fluid";
    Tr = noEvent(Mtot/max(abs(infl.m_flow), Modelica.Constants.eps))
      "Residence time";
  initial equation
    if initOpt == Choices.Init.Options.noInit then
      // do nothing
    elseif initOpt == Choices.Init.Options.steadyState then
      der(h) = zeros(N);
      if (not Medium.singleState) then
        der(p) = 0;
      end if;
    elseif initOpt == Choices.Init.Options.steadyStateNoP then
      der(h) = zeros(N);
    elseif initOpt == Choices.Init.Options.steadyStateNoT and not Medium.singleState then
      der(p) = 0;
    else
      assert(false, "Unsupported initialisation option");
    end if;
    annotation (
      Diagram(graphics),
      Icon(graphics={Text(extent={{-100,-52},{100,-82}}, textString="%name")}),
      Documentation(info="<HTML>
<p>This model describes the flow of water or steam in a rigid tube. The basic modelling assumptions are:
<ul><li>The fluid state is always one-phase (i.e. subcooled liquid or superheated steam).
<li>Uniform velocity is assumed on the cross section, leading to a 1-D distributed parameter model.
<li>Turbulent friction is always assumed; a small linear term is added to avoid numerical singularities at zero flowrate. The friction effects are not accurately computed in the laminar and transitional flow regimes, which however should not be an issue in most applications using water or steam as a working fluid.
<li>The model is based on dynamic mass, momentum, and energy balances. The dynamic momentum term can be switched off, to avoid the fast oscillations that can arise from its coupling with the mass balance (sound wave dynamics).
<li>The longitudinal heat diffusion term is neglected.
<li>The energy balance equation is written by assuming a uniform pressure distribution; the pressure drop is lumped either at the inlet or at the outlet.
<li>The fluid flow can exchange thermal power through the lateral surface, which is represented by the <tt>wall</tt> connector. The actual heat flux must be computed by a connected component (heat transfer computation module).
</ul>
<p>The mass, momentum, and energy balance equation are discretised with the finite element method. The state variables are one pressure, one flowrate (optional) and N specific enthalpies.
<p>The turbulent friction factor can be either assumed as a constant, or computed by Colebrook's equation. In the former case, the friction factor can be supplied directly, or given implicitly by a specified operating point. In any case, the multiplicative correction coefficient <tt>Kfc</tt> can be used to modify the friction coefficient, e.g. to fit experimental data.
<p>A small linear pressure drop is added to avoid numerical singularities at low or zero flowrate. The <tt>wnom</tt> parameter must be always specified: the additional linear pressure drop is such that it is equal to the turbulent pressure drop when the flowrate is equal to <tt>wnf*wnom</tt> (the default value is 1% of the nominal flowrate). Increase <tt>wnf</tt> if numerical instabilities occur in tubes with very low pressure drops.
<p>Flow reversal is fully supported.
<p><b>Modelling options</b></p>
<p>Thermal variables (enthalpy, temperature, density) are computed in <tt>N</tt> equally spaced nodes, including the inlet (node 1) and the outlet (node N); <tt>N</tt> must be greater or equal than 2.
<p>The dynamic momentum term is included or neglected depending on the <tt>DynamicMomentum</tt> parameter.
<p> Two parameters are available to tune the numerical method. The stabilisation coefficient <tt>alpha</tt> varies from 0.0 to 1.0; <tt>alpha=0.0</tt> corresponds to a non-stabilised method, which gives rise to non-physical oscillations; the default value of 1.0 corresponds to a stabilised method, with well-damped oscillations. The mass lumping coefficient (<tt>ML</tt>) allows to use a hybrid finite-element/finite-volume discretisation method for the dynamic matrix; the default value <tt>ML=0.0</tt> corresponds to a standard FEM model, <tt>ML=1.0</tt> corresponds to a full finite-volume method, with the associated numerical diffusion effects. Intermediate values can be used.
<p>The following options are available to specify the friction coefficient:
<ul><li><tt>FFtype = FFtypes.Kfnom</tt>: the hydraulic friction coefficient <tt>Kf</tt> is set directly to <tt>Kfnom</tt>.
<li><tt>FFtype = FFtypes.OpPoint</tt>: the hydraulic friction coefficient is specified by a nominal operating point (<tt>wnom</tt>,<tt>dpnom</tt>, <tt>rhonom</tt>).
<li><tt>FFtype = FFtypes.Cfnom</tt>: the friction coefficient is computed by giving the (constant) value of the Fanning friction factor <tt>Cfnom</tt>.
<li><tt>FFtype = FFtypes.Colebrook</tt>: the Fanning friction factor is computed by Colebrook's equation (assuming Re > 2100, e.g. turbulent flow).
<li><tt>FFtype = FFtypes.NoFriction</tt>: no friction is assumed across the pipe.</ul>
<p>If <tt>HydraulicCapacitance = 2</tt> (default option) then the mass buildup term depending on the pressure is lumped at the outlet, while the optional momentum buildup term depending on the flowrate is lumped at the inlet. If <tt>HydraulicCapacitance = 1</tt> the reverse takes place.
<p>Start values for pressure and flowrate are specified by <tt>pstart</tt>, <tt>wstart</tt>. The start values for the node enthalpies are linearly distributed from <tt>hstartin</tt> at the inlet to <tt>hstartout</tt> at the outlet.
<p>A bank of <tt>Nt</tt> identical tubes working in parallel can be modelled by setting <tt>Nt > 1</tt>. The geometric parameters always refer to a <i>single</i> tube.
<p>This models makes the temperature and external heat flow distributions visible through the <tt>wall</tt> connector. If other variables (e.g. the heat transfer coefficient) are needed by external components to compute the actual heat flow, the <tt>wall</tt> connector can be replaced by an extended version of the <tt>DHT</tt> connector.
</HTML>", revisions="<html>
<ul>
<li><i>24 Mar 2005</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       <tt>FFtypes</tt> package and <tt>NoFriction</tt> option added.</li>
<li><i>1 Mar 2005</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Residence time added.</li>
<li><i>16 Dec 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Standard medium definition added.</li>
<li><i>8 Oct 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Model now based on <tt>Flow1DBase</tt>.
<li><i>24 Sep 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Removed <tt>wstart</tt>, <tt>pstart</tt>. Added <tt>pstartin</tt>, <tt>pstartout</tt>.
<li><i>23 Jul 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Adapted to Modelica.Media.</li>
<li><i>1 Jul 2004</i>
    by <a href=\"mailto:francesco.schiavo@polimi.it\">Francesco Schiavo</a>:<br>
       Mass flow-rate spatial distribution treatment added.</li>
<li><i>15 Jan 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Computation of fluid velocity <i>u</i> added. Improved treatment of geometric parameters</li>
<li><i>1 Oct 2003</i>
    by <a href=\"mailto:francesco.schiavo@polimi.it\">Francesco Schiavo</a>:<br>
       First release.</li>
</ul>
</html>"));
  end Flow1Dfem;

  model Flow1Dfem2ph
    "1-dimensional fluid flow model for water/steam (finite elements)"
    extends Modelica.Icons.ObsoleteModel;
    import Modelica.Math.*;
    import ThermoPower.Choices.Flow1D.FFtypes;
    import ThermoPower.Choices.Flow1D.HCtypes;
    extends BaseClasses.Flow1DBase(redeclare replaceable package Medium =
          StandardWater "Medium model" constrainedby
        Modelica.Media.Interfaces.PartialTwoPhaseMedium);
    replaceable ThermoPower.Thermal.DHT wall(N=N) annotation (Dialog(enable=
            false), Placement(transformation(extent={{-40,40},{40,60}},
            rotation=0)));
    parameter Real alpha(
      min=0,
      max=2) = 1 "Numerical stabilization coefficient";
    parameter Real ML(
      min=0,
      max=1) = 0.2 "Mass Lumping Coefficient";
    constant Real g=Modelica.Constants.g_n;
    final parameter Boolean evenN=(div(N, 2)*2 == N)
      "The number of nodes is even";
    constant SI.Pressure pzero=10 "Small deltap for calculations";
    constant SI.Pressure pc=Medium.fluidConstants[1].criticalPressure;
    constant SI.SpecificEnthalpy hzero=1e-3;

    Medium.ThermodynamicState fluidState[N]
      "Thermodynamic state of the fluid at the nodes";
    Medium.SaturationProperties sat "Properties of saturated fluid";
    Medium.ThermodynamicState dew "Thermodynamic state at dewpoint";
    Medium.ThermodynamicState bubble "Thermodynamic state at bubblepoint";
    SI.Length omega_hyd "Hydraulic perimeter (single tube)";
    Real dwdt "Dynamic momentum term";
    Medium.AbsolutePressure p "Fluid pressure";
    SI.Pressure Dpfric "Pressure drop due to friction";
    SI.Pressure Dpfric1
      "Pressure drop due to friction (from inlet to capacitance)";
    SI.Pressure Dpfric2
      "Pressure drop due to friction (from capacitance to outlet)";
    SI.Pressure Dpstat "Pressure drop due to static head";
    SI.MassFlowRate w[N](start=wnom*ones(N)) "Mass flowrate (single tube)";
    SI.Velocity u[N] "Fluid velocity";
    SI.HeatFlux phi[N] "External heat flux";
    Medium.Temperature T[N] "Fluid temperature";
    Medium.SpecificEnthalpy h[N](start=hstart) "Fluid specific enthalpy";
    Medium.Density rho[N] "Fluid density";
    SI.SpecificVolume v[N] "Fluid specific volume";

    Medium.Temperature Ts "Saturation temperature";
    Medium.SpecificEnthalpy hl(start=Medium.bubbleEnthalpy(Medium.setSat_p(
          pstart))) "Saturated liquid specific enthalpy";
    Medium.SpecificEnthalpy hv(start=Medium.dewEnthalpy(Medium.setSat_p(pstart)))
      "Saturated vapour specific enthalpy";
    Real x[N] "Steam quality";
    Units.LiquidDensity rhol "Saturated liquid density";
    Units.GasDensity rhov "Saturated vapour density";

    Real Kf[N] "Friction coefficient";
    Real Cf[N] "Fanning friction factor";
    Real Phi[N] "Two-phase friction multiplier";
  protected
    SI.DerDensityByEnthalpy drdh[N] "Derivative of density by enthalpy";
    SI.DerDensityByPressure drdp[N] "Derivative of density by pressure";

    SI.DerDensityByPressure drl_dp
      "Derivative of liquid density by pressure just before saturation";
    SI.DerDensityByPressure drv_dp
      "Derivative of vapour density by pressure just before saturation";
    SI.DerDensityByEnthalpy drl_dh
      "Derivative of liquid density by enthalpy just before saturation";
    SI.DerDensityByEnthalpy drv_dh
      "Derivative of vapour density by enthalpy just before saturation";

    Real dhl "Derivative of saturated liquid enthalpy by pressure";
    Real dhv "Derivative of saturated vapour enthalpy by pressure";

    Real drl "Derivative of saturatd liquid density by pressure";
    Real drv "Derivative of saturated vapour density by pressure";

    SI.Density rhos[N - 1];
    SI.MassFlowRate ws[N - 1];
    Real rs[N - 1];

    Real Y[N, N];
    Real YY[N, N];

    Real Y2ph[N, N];
    Real M[N, N];
    Real D[N];
    Real D1[N];
    Real D2[N];
    Real G[N];
    Real B[N, N];
    Real B2ph[N, N];
    Real C[N, N];
    Real K[N, N];

    Real by[8, N];
    Real beta[8, N];
    //coefficients matrix for 2-phases augmented FEM matrices
    Real alpha_sgn;

    Real gamma_rho[N - 1];
    Real gamma_w[N - 1];
    //coefficients for gamma functions

    Real a;
    Real b;
    Real betap;
    Real c;
    Real d;
    Real ee[N - 1];
    Real f[N - 1];

    Real dMbif[N - 1];
    Real dMmono[N - 1];

  equation
    //All equations are referred to a single tube

    // Selection of representative pressure variable
    if HydraulicCapacitance == HCtypes.Middle then
      p = infl.p - Dpfric1 - Dpstat/2;
    elseif HydraulicCapacitance == HCtypes.Upstream then
      p = infl.p;
    elseif HydraulicCapacitance == HCtypes.Downstream then
      p = outfl.p;
    else
      assert(false, "Unsupported HydraulicCapacitance option");
    end if;

    //Friction factor calculation
    omega_hyd = 4*A/Dhyd;
    for i in 1:N loop
      if FFtype == FFtypes.NoFriction then
        Cf[i] = 0;
      elseif FFtype == FFtypes.Cfnom then
        Cf[i] = Cfnom*Kfc;
      else
        assert(true, "Unsupported friction factor selection");
      end if;
      Kf[i] = Cf[i]*omega_hyd*L/(2*A^3)
        "Relationship between friction coefficient and Fanning friction factor";
    end for;

    //Dynamic Momentum [not] accounted for
    if DynamicMomentum then
      if HydraulicCapacitance == HCtypes.Upstream then
        dwdt = -der(outfl.m_flow)/Nt;
      else
        dwdt = der(infl.m_flow)/Nt;
      end if;

    else
      dwdt = 0;
    end if;

    //Momentum balance equation
    L/A*dwdt + (outfl.p - infl.p) + Dpstat + Dpfric = 0;

    w[1] = infl.m_flow/Nt;
    w[N] = -outfl.m_flow/Nt;

    Dpfric = Dpfric1 + Dpfric2 "Total pressure drop due to friction";

    if FFtype == FFtypes.NoFriction then
      Dpfric1 = 0;
      Dpfric2 = 0;
    else
      Dpfric1 = homotopy(sum(Kf[i]/L*squareReg(w[i], wnom/Nt*wnf)*D1[i]/rho[i]*
        Phi[i] for i in 1:N), dpnom/2/(wnom/Nt)*w[1])
        "Pressure drop from inlet to capacitance";
      Dpfric2 = homotopy(sum(Kf[i]/L*squareReg(w[i], wnom/Nt*wnf)*D2[i]/rho[i]*
        Phi[i] for i in 1:N), dpnom/2/(wnom/Nt)*w[N])
        "Pressure drop from capacitance to outlet";
    end if "Pressure drop due to friction";

    for i in 1:N loop
      if FFtype == FFtypes.NoFriction or noEvent(h[i] <= hl or h[i] >= hv) then
        Phi[i] = 1;
      else
        // Chisholm-Laird formulation of Martinelli-Lockhart correlation for turbulent-turbulent flow
        // Phi_l^2 = 1 + 20/Xtt + 1/Xtt^2
        // same fixed Fanning friction factor Cfnom is assumed for liquid and vapour, so Xtt = (rhov/rhol)^0.5 * (1-x)/x
        Phi[i] = rho[i]/rhol*((1 - x[i])^2 + 20*sqrt(rhol/rhov)*x[i]*(1 - x[i])
           + rhol/rhov*x[i]^2);
      end if;
    end for;

    Dpstat = if abs(dzdx) < 1e-6 then 0 else g*dzdx*rho*D
      "Pressure drop due to static head";

    //Energy balance equations
    l/12*((1 - ML)*Y + ML*YY + 0*Y2ph)*der(h) + (1/A)*(B + 0*B2ph)*h + C*h/A =
      der(p)*G + M*(omega/A)*phi + K*w/A;

    //  (Ts,rhol,rhov,hl,hv,drl_dp,drv_dp,drl_dh,drv_dh,dhl,dhv,drl,drv) =
    //  propsat_p_2der(noEvent(min(p, pc - pzero)));

    sat.psat = p;
    sat.Tsat = Medium.saturationTemperature(p);
    Ts = sat.Tsat;
    bubble = Medium.setBubbleState(sat);
    dew = Medium.setDewState(sat);
    rhol = Medium.bubbleDensity(sat);
    rhov = Medium.dewDensity(sat);
    hl = Medium.bubbleEnthalpy(sat);
    hv = Medium.dewEnthalpy(sat);
    drl = Medium.dBubbleDensity_dPressure(sat);
    drv = Medium.dDewDensity_dPressure(sat);
    dhl = Medium.dBubbleEnthalpy_dPressure(sat);
    dhv = Medium.dDewEnthalpy_dPressure(sat);
    drl_dp = Medium.density_derp_h(bubble);
    drv_dp = Medium.density_derp_h(dew);
    drl_dh = Medium.density_derh_p(bubble);
    drv_dh = Medium.density_derh_p(dew);

    a = ((hv - hl)*(rhol^2*drv + rhov^2*drl) + rhov*rhol*(rhol - rhov)*(dhv -
      dhl))/(rhol - rhov)^2;
    betap = ((rhol - rhov)*(rhov*dhv - rhol*dhl) + (hv - hl)*(rhol*drv - rhov*
      drl))/(rhol - rhov)^2;
    b = a*c + d*betap;
    c = (rhov*hv - rhol*hl)/(rhol - rhov);
    d = -rhol*rhov*(hv - hl)/(rhol - rhov);

    //Computation of fluid properties
    for j in 1:N loop
      fluidState[j] = Medium.setState_phX(p, h[j]);
      T[j] = Medium.temperature(fluidState[j]);
      rho[j] = Medium.density(fluidState[j]);
      drdp[j] = if Medium.singleState then 0 else Medium.density_derp_h(
        fluidState[j]);
      drdh[j] = Medium.density_derh_p(fluidState[j]);
      v[j] = 1/rho[j];
      u[j] = w[j]/(rho[j]*A);
      x[j] = noEvent(min(max((h[j] - hl)/(hv - hl), 0), 1));
    end for;

    //Wall energy flux and  temperature
    T = wall.T;
    phi = wall.phi;

    //Boundary Values

    h[1] = infl.h_outflow;
    h[N] = outfl.h_outflow;

    alpha_sgn = alpha*sign(infl.m_flow - outfl.m_flow);

    //phase change determination
    for i in 1:N - 1 loop
      (w[i] - w[i + 1]) = dMmono[i] + dMbif[i];
      if noEvent(abs(h[i + 1] - h[i]) < hzero) then

        rs[i] = 0;
        rhos[i] = 0;
        gamma_rho[i] = 0;

        gamma_w[i] = 0;
        ws[i] = 0;

        dMmono[i] = A*l*(der(p)*1/2*(drdp[i + 1] + drdp[i]) + 1/6*(der(h[i])*(2
          *drdh[i] + drdh[i + 1]) + der(h[i + 1])*(drdh[i] + 2*drdh[i + 1])));

        dMbif[i] = 0;

        ee[i] = 0;
        f[i] = 0;

      elseif noEvent((h[i] < hl) and (h[i + 1] >= hl) and (h[i + 1] <= hv)) then
        //liquid - two phase

        rs[i] = (hl - h[i])/(h[i + 1] - h[i]);
        rhos[i] = rhol;
        gamma_rho[i] = (rhos[i] - rho[i]*(1 - rs[i]) - rho[i + 1]*rs[i]);

        gamma_w[i] = (ws[i] - w[i]*(1 - rs[i]) - w[i + 1]*rs[i]);

        (w[i] - ws[i]) = dMmono[i];

        dMmono[i] = A*rs[i]*l*(der(p)*1/2*(drl_dp + drdp[i]) + 1/6*(der(h[i])*(
          2*drdh[i] + drl_dh) + (der(h[i])*(1 - rs[i]) + der(h[i + 1])*rs[i])*(
          drdh[i] + 2*drl_dh)));

        dMbif[i] = A*(1 - rs[i])*l/(h[i + 1] - hl)*(der(p)*((b - a*c)*(h[i + 1]
           - hl)/((c + h[i + 1])*(c + hl)) + a*log((c + h[i + 1])/(c + hl))) +
          ((d*f[i] - d*c*ee[i])*(h[i + 1] - hl)/((c + h[i + 1])*(c + hl)) + d*
          ee[i]*log((c + h[i + 1])/(c + hl))));

        ee[i] = (der(h[i + 1]) - (der(h[i + 1])*rs[i] + der(h[i])*(1 - rs[i])))
          /(h[i + 1] - hl);
        f[i] = ((der(h[i + 1])*rs[i] + der(h[i])*(1 - rs[i]))*h[i + 1] - der(h[
          i + 1])*hl)/(h[i + 1] - hl);

      elseif noEvent((h[i] >= hl) and (h[i] <= hv) and (h[i + 1] < hl)) then
        //two phase-liquid

        rs[i] = (hl - h[i])/(h[i + 1] - h[i]);
        rhos[i] = rhol;
        gamma_rho[i] = (rhos[i] - rho[i]*(1 - rs[i]) - rho[i + 1]*rs[i]);

        gamma_w[i] = (ws[i] - w[i]*(1 - rs[i]) - w[i + 1]*rs[i]);

        (w[i] - ws[i]) = dMbif[i];

        dMmono[i] = A*(1 - rs[i])*l*(der(p)*1/2*(drdp[i + 1] + drl_dp) + 1/6*(
          der(h[i])*(2*drl_dh + drdh[i + 1]) + (der(h[i + 1])*rs[i] + der(h[i])
          *(1 - rs[i]))*(drl_dh + 2*drdh[i + 1])));

        dMbif[i] = A*rs[i]*l/(hl - h[i])*(der(p)*((b - a*c)*(hl - h[i])/((c +
          hl)*(c + h[i])) + a*log((c + hl)/(c + h[i]))) + ((d*f[i] - d*c*ee[i])
          *(hl - h[i])/((c + hl)*(c + h[i])) + d*ee[i]*log((c + hl)/(c + h[i]))));

        ee[i] = ((der(h[i + 1])*rs[i] + der(h[i])*(1 - rs[i])) - der(h[i]))/(hl
           - h[i]);
        f[i] = (der(h[i])*hl - (der(h[i + 1])*rs[i] + der(h[i])*(1 - rs[i]))*h[
          i])/(hl - h[i]);

      elseif noEvent((h[i] >= hl) and (h[i] <= hv) and (h[i + 1] > hv)) then
        //two phase - vapour

        rs[i] = (hv - h[i])/(h[i + 1] - h[i]);
        rhos[i] = rhov;
        gamma_rho[i] = (rhos[i] - rho[i]*(1 - rs[i]) - rho[i + 1]*rs[i]);

        gamma_w[i] = (ws[i] - w[i]*(1 - rs[i]) - w[i + 1]*rs[i]);
        (w[i] - ws[i]) = dMbif[i];

        dMmono[i] = A*(1 - rs[i])*l*(der(p)*1/2*(drdp[i + 1] + drv_dp) + 1/6*(
          der(h[i])*(2*drv_dh + drdh[i + 1]) + (der(h[i + 1])*rs[i] + der(h[i])
          *(1 - rs[i]))*(drv_dh + 2*drdh[i + 1])));

        dMbif[i] = A*rs[i]*l/(hv - h[i])*(der(p)*((b - a*c)*(hv - h[i])/((c +
          hv)*(c + h[i])) + a*log((c + hv)/(c + h[i]))) + ((d*f[i] - d*c*ee[i])
          *(hv - h[i])/((c + hv)*(c + h[i])) + d*ee[i]*log((c + hv)/(c + h[i]))));

        ee[i] = ((der(h[i + 1])*rs[i] + der(h[i])*(1 - rs[i])) - der(h[i]))/(hv
           - h[i]);
        f[i] = (der(h[i])*hv - (der(h[i + 1])*rs[i] + der(h[i])*(1 - rs[i]))*h[
          i])/(hv - h[i]);

      elseif noEvent((h[i] > hv) and (h[i + 1] >= hl) and (h[i + 1] <= hv)) then
        // vapour - two phase

        rs[i] = (hv - h[i])/(h[i + 1] - h[i]);
        rhos[i] = rhov;
        gamma_rho[i] = (rhos[i] - rho[i]*(1 - rs[i]) - rho[i + 1]*rs[i]);

        gamma_w[i] = (ws[i] - w[i]*(1 - rs[i]) - w[i + 1]*rs[i]);
        (w[i] - ws[i]) = dMmono[i];

        dMmono[i] = A*rs[i]*l*(der(p)*1/2*(drv_dp + drdp[i]) + 1/6*(der(h[i])*(
          2*drdh[i] + drv_dh) + (der(h[i])*(1 - rs[i]) + der(h[i + 1])*rs[i])*(
          drdh[i] + 2*drv_dh)));

        dMbif[i] = A*(1 - rs[i])*(der(p)*((b - a*c)*(h[i + 1] - hv)/((c + h[i
           + 1])*(c + hv)) + a*log((c + h[i + 1])/(c + hv))) + ((d*f[i] - d*c*
          ee[i])*(h[i + 1] - hv)/((c + h[i + 1])*(c + hv)) + d*ee[i]*log((c + h[
          i + 1])/(c + hv))));

        ee[i] = (der(h[i + 1]) - (der(h[i + 1])*rs[i] + der(h[i])*(1 - rs[i])))
          /(h[i + 1] - hv);
        f[i] = ((der(h[i + 1])*rs[i] + der(h[i])*(1 - rs[i]))*h[i + 1] - der(h[
          i + 1])*hv)/(h[i + 1] - hv);

      elseif noEvent((h[i] >= hl) and (h[i] <= hv) and (h[i + 1] >= hl) and (h[
          i + 1] <= hv)) then
        //two phase

        rs[i] = 0;
        rhos[i] = 0;
        gamma_rho[i] = 0;

        gamma_w[i] = 0;

        ws[i] = 0;

        dMmono[i] = 0;

        dMbif[i] = A*l/(h[i + 1] - h[i])*(der(p)*((b - a*c)*(h[i + 1] - h[i])/(
          (c + h[i + 1])*(c + h[i])) + a*log((c + h[i + 1])/(c + h[i]))) + ((d*
          f[i] - d*c*ee[i])*(h[i + 1] - h[i])/((c + h[i + 1])*(c + h[i])) + d*
          ee[i]*log((c + h[i + 1])/(c + h[i]))));

        ee[i] = (der(h[i + 1]) - der(h[i]))/(h[i + 1] - h[i]);
        f[i] = (der(h[i])*h[i + 1] - der(h[i + 1])*h[i])/(h[i + 1] - h[i]);

      elseif noEvent(((h[i] < hl) and (h[i + 1] < hl)) or ((h[i] > hv) and (h[i
           + 1] > hv))) then
        //single-phase

        rs[i] = 0;
        rhos[i] = 0;
        gamma_rho[i] = 0;

        gamma_w[i] = 0;
        ws[i] = 0;

        dMmono[i] = A*l*(der(p)*1/2*(drdp[i + 1] + drdp[i]) + 1/6*(der(h[i])*(2
          *drdh[i] + drdh[i + 1]) + der(h[i + 1])*(drdh[i] + 2*drdh[i + 1])));
        dMbif[i] = 0;

        ee[i] = 0;
        f[i] = 0;
      else
        //double transition (not supported!)
        assert(0 > 1,
          "Error: two phase transitions between two adiacent nodes. Try increasing the number of nodes");
        rs[i] = 0;
        rhos[i] = 0;
        gamma_rho[i] = 0;

        gamma_w[i] = 0;
        ws[i] = 0;

        dMmono[i] = 0;
        dMbif[i] = 0;

        ee[i] = 0;
        f[i] = 0;
      end if;
    end for;

    // Energy equation FEM matrices

    Y[1, 1] = rho[1]*(3 - 2*alpha_sgn) + rho[2]*(1 - alpha_sgn);
    Y[1, 2] = rho[1]*(1 - alpha_sgn) + rho[2]*(1 - 2*alpha_sgn);
    Y[N, N] = rho[N - 1]*(alpha_sgn + 1) + rho[N]*(3 + 2*alpha_sgn);
    Y[N, N - 1] = rho[N - 1]*(1 + 2*alpha_sgn) + rho[N]*(1 + alpha_sgn);
    if N > 2 then
      for i in 2:N - 1 loop
        Y[i, i - 1] = rho[i - 1]*(1 + 2*alpha_sgn) + rho[i]*(1 + alpha_sgn);
        Y[i, i] = rho[i - 1]*(1 + alpha_sgn) + rho[i]*6 + rho[i + 1]*(1 -
          alpha_sgn);
        Y[i, i + 1] = rho[i]*(1 - alpha_sgn) + rho[i + 1]*(1 - 2*alpha_sgn);
        Y[1, i + 1] = 0;
        Y[N, i - 1] = 0;
        for j in 1:(i - 2) loop
          Y[i, j] = 0;
        end for;
        for j in (i + 2):N loop
          Y[i, j] = 0;
        end for;
      end for;
    end if;

    for i in 1:N loop
      for j in 1:N loop
        YY[i, j] = if (i <> j) then 0 else sum(Y[:, j]);
      end for;
    end for;

    M[1, 1] = l/3 - l*alpha_sgn/4;
    M[N, N] = l/3 + l*alpha_sgn/4;
    M[1, 2] = l/6 - l*alpha_sgn/4;
    M[N, (N - 1)] = l/6 + l*alpha_sgn/4;
    if N > 2 then
      for i in 2:N - 1 loop
        M[i, i - 1] = l/6 + l*alpha_sgn/4;
        M[i, i] = 2*l/3;
        M[i, i + 1] = l/6 - l*alpha_sgn/4;
        M[1, i + 1] = 0;
        M[N, i - 1] = 0;
        for j in 1:(i - 2) loop
          M[i, j] = 0;
        end for;
        for j in (i + 2):N loop
          M[i, j] = 0;
        end for;
      end for;
    end if;

    B[1, 1] = (-1/3 + alpha_sgn/4)*w[1] + (-1/6 + alpha_sgn/4)*w[2];
    B[1, 2] = (1/3 - alpha_sgn/4)*w[1] + (1/6 - alpha_sgn/4)*w[2];
    B[N, N] = (1/6 + alpha_sgn/4)*w[N - 1] + (1/3 + alpha_sgn/4)*w[N];
    B[N, N - 1] = (-1/6 - alpha_sgn/4)*w[N - 1] + (-1/3 - alpha_sgn/4)*w[N];
    if N > 2 then
      for i in 2:N - 1 loop
        B[i, i - 1] = (-1/6 - alpha_sgn/4)*w[i - 1] + (-1/3 - alpha_sgn/4)*w[i];
        B[i, i] = (1/6 + alpha_sgn/4)*w[i - 1] + (alpha_sgn/2)*w[i] + (-1/6 +
          alpha_sgn/4)*w[i + 1];
        B[i, i + 1] = (1/3 - alpha_sgn/4)*w[i] + (1/6 - alpha_sgn/4)*w[i + 1];
        B[1, i + 1] = 0;
        B[N, i - 1] = 0;
        for j in 1:(i - 2) loop
          B[i, j] = 0;
        end for;
        for j in (i + 2):N loop
          B[i, j] = 0;
        end for;
      end for;
    end if;

    G[1] = l/2*(1 - alpha_sgn);
    G[N] = l/2*(1 + alpha_sgn);
    if N > 2 then
      for i in 2:N - 1 loop
        G[i] = l;
      end for;
    end if;

    //boundary conditions

    C[1, 1] = if noEvent(infl.m_flow >= 0) then (1 - alpha_sgn/2)*w[1] else 0;
    C[N, N] = if noEvent(outfl.m_flow >= 0) then -(1 + alpha_sgn/2)*w[N] else 0;
    C[N, 1] = 0;
    C[1, N] = 0;
    if (N > 2) then
      for i in 2:(N - 1) loop
        C[1, i] = 0;
        C[N, i] = 0;
        for j in 1:N loop
          C[i, j] = 0;
        end for;
      end for;
    end if;

    K[1, 1] = if noEvent(infl.m_flow >= 0) then (1 - alpha_sgn/2)*inStream(infl.h_outflow)
       else 0;
    K[N, N] = if noEvent(outfl.m_flow >= 0) then -(1 + alpha_sgn/2)*inStream(
      outfl.h_outflow) else 0;
    K[N, 1] = 0;
    K[1, N] = 0;
    if (N > 2) then
      for i in 2:(N - 1) loop
        K[1, i] = 0;
        K[N, i] = 0;
        for j in 1:N loop
          K[i, j] = 0;
        end for;
      end for;
    end if;

    // Momentum and Mass balance equation matrices
    D[1] = l/2;
    D[N] = l/2;
    for i in 2:N - 1 loop
      D[i] = l;
    end for;
    if HydraulicCapacitance == HCtypes.Middle then
      D1 = l*(if N == 2 then {3/8,1/8} else if evenN then cat(
          1,
          {1/2},
          ones(max(0, div(N, 2) - 2)),
          {7/8,1/8},
          zeros(div(N, 2) - 1)) else cat(
          1,
          {1/2},
          ones(div(N, 2) - 1),
          {1/2},
          zeros(div(N, 2))));
      D2 = l*(if N == 2 then {1/8,3/8} else if evenN then cat(
          1,
          zeros(div(N, 2) - 1),
          {1/8,7/8},
          ones(max(div(N, 2) - 2, 0)),
          {1/2}) else cat(
          1,
          zeros(div(N, 2)),
          {1/2},
          ones(div(N, 2) - 1),
          {1/2}));
    elseif HydraulicCapacitance == HCtypes.Upstream then
      D1 = zeros(N);
      D2 = D;
    elseif HydraulicCapacitance == HCtypes.Downstream then
      D1 = D;
      D2 = zeros(N);
    else
      assert(false, "Unsupported HydraulicCapacitance option");
    end if;

    by[1, 1] = 0;
    by[2, 1] = 0;
    by[3, 1] = l/12*rs[1]*(6 - 8*rs[1] + 3*rs[1]^2 + alpha_sgn*(2*rs[1] - 3));
    by[4, 1] = -l/12*(1 - rs[1])^2*(2*alpha_sgn + 3*rs[1] - 3);
    by[5, 1] = -l/12*rs[1]^2*(2*alpha_sgn + 3*rs[1] - 4);
    by[6, 1] = -l/12*(1 - rs[1])*(3*rs[1]^2 - 2*rs[1] + 2*alpha_sgn*rs[1] +
      alpha_sgn - 1);
    by[7, 1] = 0;
    by[8, 1] = 0;
    by[1, N] = l/12*rs[N - 1]^2*(2*alpha_sgn + 3*rs[N - 1]);
    by[2, N] = l/12*(1 - rs[N - 1])*(1 + alpha_sgn + 2*rs[N - 1] + 2*alpha_sgn*
      rs[N - 1] + 3*rs[N - 1]^2);
    by[3, N] = 0;
    by[4, N] = 0;
    by[5, N] = 0;
    by[6, N] = 0;
    by[7, N] = l/12*rs[N - 1]*(alpha_sgn*(3 - 2*rs[N - 1]) + rs[N - 1]*(4 - 3*
      rs[N - 1]));
    by[8, N] = l/12*(1 - rs[N - 1])^2*(2*alpha_sgn + 3*rs[N - 1] + 1);
    if N > 2 then
      for i in 2:N - 1 loop
        by[1, i] = l/12*rs[i - 1]^2*(2*alpha_sgn + 3*rs[i - 1]);
        by[2, i] = l/12*(1 - rs[i - 1])*(1 + alpha_sgn + 2*rs[i - 1] + 2*
          alpha_sgn*rs[i - 1] + 3*rs[i - 1]^2);
        by[3, i] = l/12*rs[i]*(6 - 8*rs[i] + 3*rs[i]^2 + alpha_sgn*(2*rs[i] - 3));
        by[4, i] = -l/12*(1 - rs[i])^2*(2*alpha_sgn + 3*rs[i] - 3);
        by[5, i] = -l/12*rs[i]^2*(2*alpha_sgn + 3*rs[i] - 4);
        by[6, i] = -l/12*(1 - rs[i])*(3*rs[i]^2 - 2*rs[i] + 2*alpha_sgn*rs[i]
           + alpha_sgn - 1);
        by[7, i] = l/12*rs[i - 1]*(alpha_sgn*(3 - 2*rs[i - 1]) + rs[i - 1]*(4
           - 3*rs[i - 1]));
        by[8, i] = l/12*(1 - rs[i - 1])^2*(2*alpha_sgn + 3*rs[i - 1] + 1);
      end for;
    end if;

    //additional 2 phases Y-matrix
    Y2ph[1, 1] = (gamma_rho[1]*by[3, 1] + gamma_rho[1]*by[4, 1]);
    Y2ph[1, 2] = (gamma_rho[1]*by[5, 1] + gamma_rho[1]*by[6, 1]);
    Y2ph[N, N] = (gamma_rho[N - 1]*by[1, N] + gamma_rho[N - 1]*by[2, N]);
    Y2ph[N, N - 1] = (gamma_rho[N - 1]*by[7, N] + gamma_rho[N - 1]*by[8, N]);
    if N > 2 then
      for i in 2:N - 1 loop
        Y2ph[i, i - 1] = (gamma_rho[i - 1]*by[7, i] + gamma_rho[i - 1]*by[8, i]);
        Y2ph[i, i] = (gamma_rho[i - 1]*by[1, i] + gamma_rho[i - 1]*by[2, i]) +
          (gamma_rho[i]*by[3, i] + gamma_rho[i]*by[4, i]);
        Y2ph[i, i + 1] = (gamma_rho[i]*by[5, i] + gamma_rho[i]*by[6, i]);
        Y2ph[1, i + 1] = 0;
        Y2ph[N, i - 1] = 0;
        for j in 1:(i - 2) loop
          Y2ph[i, j] = 0;
        end for;
        for j in (i + 2):N loop
          Y2ph[i, j] = 0;
        end for;
      end for;
    end if;

    //computation of beta functions for additional matrices
    beta[1, 1] = 0;
    beta[2, 1] = 0;
    beta[3, 1] = 1/12*rs[1]*(3*alpha_sgn + 4*rs[1] - 6);
    beta[4, 1] = 1/12*(1 - rs[1])*(3*alpha_sgn + 4*rs[1] - 4);
    beta[5, 1] = -beta[3, 1];
    beta[6, 1] = -beta[4, 1];
    beta[7, 1] = 0;
    beta[8, 1] = 0;
    beta[1, N] = 1/12*rs[N - 1]*(3*alpha_sgn + 4*rs[N - 1]);
    beta[2, N] = 1/12*(1 - rs[N - 1])*(3*alpha_sgn + 4*rs[N - 1] + 2);
    beta[3, N] = 0;
    beta[4, N] = 0;
    beta[5, N] = 0;
    beta[6, N] = 0;
    beta[7, N] = -beta[1, N];
    beta[8, N] = -beta[2, N];
    if N > 2 then
      for i in 2:N - 1 loop
        beta[1, i] = 1/12*rs[i - 1]*(3*alpha_sgn + 4*rs[i - 1]);
        beta[2, i] = 1/12*(1 - rs[i - 1])*(3*alpha_sgn + 4*rs[i - 1] + 2);
        beta[3, i] = 1/12*rs[i]*(3*alpha_sgn + 4*rs[i] - 6);
        beta[4, i] = 1/12*(1 - rs[i])*(3*alpha_sgn + 4*rs[i] - 4);
        beta[5, i] = -beta[3, i];
        beta[6, i] = -beta[4, i];
        beta[7, i] = -beta[1, i];
        beta[8, i] = -beta[2, i];
      end for;
    end if;

    //additional 2 phases B-matrix
    B2ph[1, 1] = (gamma_w[1]*beta[3, 1] + gamma_w[1]*beta[4, 1]);
    B2ph[1, 2] = (gamma_w[1]*beta[5, 1] + gamma_w[1]*beta[6, 1]);
    B2ph[N, N] = (gamma_w[N - 1]*beta[1, N] + gamma_w[N - 1]*beta[2, N]);
    B2ph[N, N - 1] = (gamma_w[N - 1]*beta[7, N] + gamma_w[N - 1]*beta[8, N]);
    if N > 2 then
      for i in 2:N - 1 loop
        B2ph[i, i - 1] = (gamma_w[i - 1]*beta[7, i] + gamma_w[i - 1]*beta[8, i]);
        B2ph[i, i] = (gamma_w[i - 1]*beta[1, i] + gamma_w[i - 1]*beta[2, i]) +
          (gamma_w[i]*beta[3, i] + gamma_w[i]*beta[4, i]);
        B2ph[i, i + 1] = (gamma_w[i]*beta[5, i] + gamma_w[i]*beta[6, i]);
        B2ph[1, i + 1] = 0;
        B2ph[N, i - 1] = 0;
        for j in 1:(i - 2) loop
          B2ph[i, j] = 0;
        end for;
        for j in (i + 2):N loop
          B2ph[i, j] = 0;
        end for;
      end for;
    end if;
    Q = Nt*omega*D*phi "Total heat flow through lateral boundary";
    Tr = noEvent(sum(rho)*A*l/max(infl.m_flow/Nt, Modelica.Constants.eps));
  initial equation
    if initOpt == Choices.Init.Options.noInit then
      // do nothing
    elseif initOpt == Choices.Init.Options.steadyState then
      der(h) = zeros(N);
      if (not Medium.singleState) then
        der(p) = 0;
      end if;
    elseif initOpt == Choices.Init.Options.steadyStateNoP then
      der(h) = zeros(N);
    else
      assert(false, "Unsupported initialisation option");
    end if;
    annotation (
      Diagram(graphics),
      Icon(graphics={Text(extent={{-100,-52},{100,-82}}, textString="%name")}),
      Documentation(info="<HTML>
<p>This model describes the flow of water or steam in a rigid tube. The basic modelling assumptions are:
<ul><li>The fluid state is either one-phase, or a two-phase mixture.
<li>In case of two-phase flow, the same velocity is assumed for both phases (homogeneous model).
<li>Uniform velocity is assumed on the cross section, leading to a 1-D distributed parameter model.
<li>Turbulent friction is always assumed; a small linear term is added to avoid numerical singularities at zero flowrate. The friction effects are not accurately computed in the laminar and transitional flow regimes, which however should not be an issue in most applications using water or steam as a working fluid.
<li>The model is based on dynamic mass, momentum, and energy balances. The dynamic momentum term can be switched off, to avoid the fast oscillations that can arise from its coupling with the mass balance (sound wave dynamics).
<li>The longitudinal heat diffusion term is neglected.
<li>The energy balance equation is written by assuming a uniform pressure distribution; the pressure drop is lumped either at the inlet or at the outlet.
<li>The fluid flow can exchange thermal power through the lateral surface, which is represented by the <tt>wall</tt> connector. The actual heat flux must be computed by a connected component (heat transfer computation module).
</ul>
<p>The mass, momentum, and energy balance equation are discretised with the Finite Element Method (Stabilised Galerkin Least Squares). The state variables are one pressure, one flowrate (optional) and N specific enthalpies.
<p>The turbulent friction factor can be either assumed as a constant, or computed by Colebrook's equation. In the former case, the friction factor can be supplied directly, or given implicitly by a specified operating point. In any case, the multiplicative correction coefficient <tt>Kfc</tt> can be used to modify the friction coefficient, e.g. to fit experimental data.
<p>A small linear pressure drop is added to avoid numerical singularities at low or zero flowrate. The <tt>wnom</tt> parameter must be always specified: the additional linear pressure drop is such that it is equal to the turbulent pressure drop when the flowrate is equal to <tt>wnf*wnom</tt> (the default value is 1% of the nominal flowrate). Increase <tt>wnf</tt> if numerical instabilities occur in tubes with very low pressure drops.
<p>Flow reversal is fully supported.
<p><b>Modelling options</b></p>
<p>Thermal variables (enthalpy, temperature, density) are computed in <tt>N</tt> equally spaced nodes, including the inlet (node 1) and the outlet (node N); <tt>N</tt> must be greater or equal than 2.
<p>The dynamic momentum term is included or neglected depending on the <tt>DynamicMomentum</tt> parameter.
<p> Two parameters are available to tune the numerical method. The stabilisation coefficient <tt>alpha</tt> varies from 0.0 to 1.0; <tt>alpha=0.0</tt> corresponds to a non-stabilised method, which gives rise to non-physical oscillations; the default value of 1.0 corresponds to a stabilised method, with well-damped oscillations. The mass lumping coefficient (<tt>ML</tt>) allows to use a hybrid finite-element/finite-volume discretisation method for the dynamic matrix; the default value <tt>ML=0.0</tt> corresponds to a standard FEM model, <tt>ML=1.0</tt> corresponds to a full finite-volume method, with the associated numerical diffusion effects. Intermediate values can be used.
<p>The following options are available to specify the friction coefficient:
<ul><li><tt>FFtype = FFtypes.Kfnom</tt>: the hydraulic friction coefficient <tt>Kf</tt> is set directly to <tt>Kfnom</tt>.
<li><tt>FFtype = FFtypes.OpPoint</tt>: the hydraulic friction coefficient is specified by a nominal operating point (<tt>wnom</tt>,<tt>dpnom</tt>, <tt>rhonom</tt>).
<li><tt>FFtype = FFtypes.Cfnom</tt>: the friction coefficient is computed by giving the (constant) value of the Fanning friction factor <tt>Cfnom</tt>.
<li><tt>FFtype = FFtypes.Colebrook</tt>: the Fanning friction factor is computed by Colebrook's equation (assuming Re > 2100, e.g. turbulent flow).
<li><tt>FFtype = FFtypes.NoFriction</tt>: no friction is assumed across the pipe.</ul><p>If <tt>HydraulicCapacitance = 2</tt> (default option) then the mass buildup term depending on the pressure is lumped at the outlet, while the optional momentum buildup term depending on the flowrate is lumped at the inlet. If <tt>HydraulicCapacitance = 1</tt> the reverse takes place.
<p>Start values for pressure and flowrate are specified by <tt>pstart</tt>, <tt>wstart</tt>. The start values for the node enthalpies are linearly distributed from <tt>hstartin</tt> at the inlet to <tt>hstartout</tt> at the outlet.
<p>A bank of <tt>Nt</tt> identical tubes working in parallel can be modelled by setting <tt>Nt > 1</tt>. The geometric parameters always refer to a <i>single</i> tube.
<p>This models makes the temperature and external heat flow distributions visible through the <tt>wall</tt> connector. If other variables (e.g. the heat transfer coefficient) are needed by external components to compute the actual heat flow, the <tt>wall</tt> connector can be replaced by an extended version of the <tt>DHT</tt> connector.
</HTML>", revisions="<html>
<ul>
<li><i>30 May 2005</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Initialisation support added.</li>
<li><i>24 Mar 2005</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       <tt>FFtypes</tt> package and <tt>NoFriction</tt> option added.
       <br>Residence time added</li>
<li><i>16 Dec 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Standard medium definition added.</li>
<li><i>8 Oct 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Model now based on <tt>Flow1DBase</tt>.
<li><i>24 Sep 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Removed <tt>wstart</tt>, <tt>pstart</tt>. Added <tt>pstartin</tt>, <tt>pstartout</tt>.
<li><i>23 Jul 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Adapted to Modelica.Media.</li>
<li><i>1 Jul 2004</i>
    by <a href=\"mailto:francesco.schiavo@polimi.it\">Francesco Schiavo</a>:<br>
       First release.</li>
</ul>
</html>
"));
  end Flow1Dfem2ph;

  model SourceP "Pressure source for water/steam flows"
    extends Icons.Water.SourceP;
    extends Modelica.Icons.ObsoleteModel;
    replaceable package Medium = StandardWater constrainedby
      Modelica.Media.Interfaces.PartialMedium "Medium model";
    parameter SI.Pressure p0=1.01325e5 "Nominal pressure";
    parameter Units.HydraulicResistance R=0 "Hydraulic resistance";
    parameter Medium.SpecificEnthalpy h=1e5 "Nominal specific enthalpy";
    parameter Boolean allowFlowReversal=system.allowFlowReversal
      "= true to allow flow reversal, false restricts to design direction"
      annotation(Evaluate=true);
    outer ThermoPower.System system "System wide properties";
    Medium.AbsolutePressure p "Actual pressure";
    FlangeB flange(redeclare package Medium = Medium, m_flow(max=if
            allowFlowReversal then +Modelica.Constants.inf else 0)) annotation (
       Placement(transformation(extent={{80,-20},{120,20}}, rotation=0)));
    Modelica.Blocks.Interfaces.RealInput in_p0 annotation (Placement(
          transformation(
          origin={-40,92},
          extent={{-20,-20},{20,20}},
          rotation=270)));
    Modelica.Blocks.Interfaces.RealInput in_h annotation (Placement(
          transformation(
          origin={40,90},
          extent={{-20,-20},{20,20}},
          rotation=270)));
  equation
    if R == 0 then
      flange.p = p;
    else
      flange.p = p + flange.m_flow*R;
    end if;

    p = in_p0;
    if cardinality(in_p0) == 0 then
      in_p0 = p0 "Pressure set by parameter";
    end if;

    flange.h_outflow = in_h;
    if cardinality(in_h) == 0 then
      in_h = h "Enthalpy set by parameter";
    end if;
    annotation (
      Diagram(graphics),
      Icon(graphics={Text(extent={{-106,90},{-52,50}}, textString="p0"), Text(
              extent={{66,90},{98,52}}, textString="h")}),
      Documentation(info="<HTML>
<p><b>Modelling options</b></p>
<p>If <tt>R</tt> is set to zero, the pressure source is ideal; otherwise, the outlet pressure decreases proportionally to the outgoing flowrate.</p>
<p>If the <tt>in_p0</tt> connector is wired, then the source pressure is given by the corresponding signal, otherwise it is fixed to <tt>p0</tt>.</p>
<p>If the <tt>in_h</tt> connector is wired, then the source pressure is given by the corresponding signal, otherwise it is fixed to <tt>h</tt>.</p>
</HTML>", revisions="<html>
<ul>
<li><i>16 Dec 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Medium model and standard medium definition added.</li>
<li><i>18 Jun 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Removed <tt>p0_fix</tt> and <tt>hfix</tt>; the connection of external signals is now detected automatically.</li>
<li><i>1 Oct 2003</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       First release.</li>
</ul>
</html>"));
  end SourceP;

  model SinkP "Pressure sink for water/steam flows"
    extends Icons.Water.SourceP;
    extends Modelica.Icons.ObsoleteModel;
    replaceable package Medium = StandardWater constrainedby
      Modelica.Media.Interfaces.PartialMedium "Medium model";
    parameter Medium.AbsolutePressure p0=1.01325e5 "Nominal pressure";
    parameter Units.HydraulicResistance R=0 "Hydraulic resistance"
      annotation (Evaluate=true);
    parameter Medium.SpecificEnthalpy h=1e5 "Nominal specific enthalpy";
    parameter Boolean allowFlowReversal=system.allowFlowReversal
      "= true to allow flow reversal, false restricts to design direction"
      annotation(Evaluate=true);
    outer ThermoPower.System system "System wide properties";
    Medium.AbsolutePressure p;
    FlangeA flange(redeclare package Medium = Medium, m_flow(min=if
            allowFlowReversal then -Modelica.Constants.inf else 0)) annotation (
       Placement(transformation(extent={{-120,-20},{-80,20}}, rotation=0)));
    Modelica.Blocks.Interfaces.RealInput in_p0 annotation (Placement(
          transformation(
          origin={-40,88},
          extent={{-20,-20},{20,20}},
          rotation=270)));
    Modelica.Blocks.Interfaces.RealInput in_h annotation (Placement(
          transformation(
          origin={40,88},
          extent={{-20,-20},{20,20}},
          rotation=270)));
  equation
    if R == 0 then
      flange.p = p;
    else
      flange.p = p + flange.m_flow*R;
    end if;

    p = in_p0;
    if cardinality(in_p0) == 0 then
      in_p0 = p0 "Pressure set by parameter";
    end if;

    flange.h_outflow = in_h;
    if cardinality(in_h) == 0 then
      in_h = h "Enthalpy set by parameter";
    end if;
    annotation (
      Icon(graphics={Text(extent={{-106,92},{-56,50}}, textString="p0"), Text(
              extent={{54,94},{112,52}}, textString="h")}),
      Diagram(graphics),
      Documentation(info="<HTML>
<p><b>Modelling options</b></p>
<p>If <tt>R</tt> is set to zero, the pressure sink is ideal; otherwise, the inlet pressure increases proportionally to the incoming flowrate.</p>
<p>If the <tt>in_p0</tt> connector is wired, then the source pressure is given by the corresponding signal, otherwise it is fixed to <tt>p0</tt>.</p>
<p>If the <tt>in_h</tt> connector is wired, then the source pressure is given by the corresponding signal, otherwise it is fixed to <tt>h</tt>.</p>
</HTML>", revisions="<html>
<ul>
<li><i>16 Dec 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Medium model and standard medium definition added.</li>
<li><i>18 Jun 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Removed <tt>p0_fix</tt> and <tt>hfix</tt>; the connection of external signals is now detected automatically.</li>
<li><i>1 Oct 2003</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       First release.</li>
</ul>
</html>"));
  end SinkP;

  model SourceW "Flowrate source for water/steam flows"
    extends Icons.Water.SourceW;
    extends Modelica.Icons.ObsoleteModel;
    replaceable package Medium = StandardWater constrainedby
      Modelica.Media.Interfaces.PartialMedium "Medium model";
    parameter SI.MassFlowRate w0=0 "Nominal mass flowrate";
    parameter Medium.AbsolutePressure p0=1e5 "Nominal pressure";
    parameter Units.HydraulicConductance G=0 "Hydraulic conductance";
    parameter Medium.SpecificEnthalpy h=1e5 "Nominal specific enthalpy";
    parameter Boolean allowFlowReversal=system.allowFlowReversal
      "= true to allow flow reversal, false restricts to design direction"
      annotation(Evaluate=true);
    outer ThermoPower.System system "System wide properties";
    Medium.MassFlowRate w "Mass flowrate";
    FlangeB flange(redeclare package Medium = Medium, m_flow(max=if
            allowFlowReversal then +Modelica.Constants.inf else 0)) annotation (
       Placement(transformation(extent={{80,-20},{120,20}}, rotation=0)));
    Modelica.Blocks.Interfaces.RealInput in_w0 annotation (Placement(
          transformation(
          origin={-40,60},
          extent={{-20,-20},{20,20}},
          rotation=270)));
    Modelica.Blocks.Interfaces.RealInput in_h annotation (Placement(
          transformation(
          origin={40,60},
          extent={{-20,-20},{20,20}},
          rotation=270)));
  equation
    if G == 0 then
      flange.m_flow = -w;
    else
      flange.m_flow = -w + (flange.p - p0)*G;
    end if;

    w = in_w0;
    if cardinality(in_w0) == 0 then
      in_w0 = w0 "Flow rate set by parameter";
    end if;

    flange.h_outflow = in_h "Enthalpy set by connector";
    if cardinality(in_h) == 0 then
      in_h = h "Enthalpy set by parameter";
    end if;
    annotation (
      Icon(graphics={Text(extent={{-98,74},{-48,42}}, textString="w0"), Text(
              extent={{48,74},{98,42}}, textString="h")}),
      Diagram(graphics),
      Documentation(info="<HTML>
<p><b>Modelling options</b></p>
<p>If <tt>G</tt> is set to zero, the flowrate source is ideal; otherwise, the outgoing flowrate decreases proportionally to the outlet pressure.</p>
<p>If the <tt>in_w0</tt> connector is wired, then the source pressure is given by the corresponding signal, otherwise it is fixed to <tt>p0</tt>.</p>
<p>If the <tt>in_h</tt> connector is wired, then the source pressure is given by the corresponding signal, otherwise it is fixed to <tt>h</tt>.</p>
</HTML>", revisions="<html>
<ul>
<li><i>16 Dec 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Medium model and standard medium definition added.</li>
<li><i>18 Jun 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Removed <tt>p0_fix</tt> and <tt>hfix</tt>; the connection of external signals is now detected automatically.</li>
<li><i>1 Oct 2003</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       First release.</li>
</ul>
</html>"));
  end SourceW;

  model SinkW "Flowrate sink for water/steam flows"
    extends Icons.Water.SourceW;
    extends Modelica.Icons.ObsoleteModel;
    replaceable package Medium = StandardWater constrainedby
      Modelica.Media.Interfaces.PartialMedium "Medium model";
    parameter Medium.MassFlowRate w0=0 "Nominal mass flowrate";
    parameter Medium.AbsolutePressure p0=1e5 "Nominal pressure";
    parameter Units.HydraulicConductance G=0 "Hydraulic conductance";
    parameter Medium.SpecificEnthalpy h=1e5 "Nominal specific enthalpy";
    parameter Boolean allowFlowReversal=system.allowFlowReversal
      "= true to allow flow reversal, false restricts to design direction"
      annotation(Evaluate=true);
    outer ThermoPower.System system "System wide properties";
    Medium.MassFlowRate w "Mass flowrate";
    FlangeA flange(redeclare package Medium = Medium, m_flow(min=if
            allowFlowReversal then -Modelica.Constants.inf else 0)) annotation (
       Placement(transformation(extent={{-120,-20},{-80,20}}, rotation=0)));
    Modelica.Blocks.Interfaces.RealInput in_w0 annotation (Placement(
          transformation(
          origin={-40,60},
          extent={{-20,-20},{20,20}},
          rotation=270)));
    Modelica.Blocks.Interfaces.RealInput in_h annotation (Placement(
          transformation(
          origin={40,60},
          extent={{-20,-20},{20,20}},
          rotation=270)));
  equation
    if G == 0 then
      flange.m_flow = w;
    else
      flange.m_flow = w + (flange.p - p0)*G;
    end if;

    w = in_w0 "Flow rate set by connector";
    if cardinality(in_w0) == 0 then
      in_w0 = w0 "Flow rate set by parameter";
    end if;

    flange.h_outflow = in_h "Enthalpy set by connector";
    if cardinality(in_h) == 0 then
      in_h = h "Enthalpy set by parameter";
    end if;
    annotation (
      Icon(graphics={Text(extent={{-98,72},{-48,40}}, textString="w0"), Text(
              extent={{48,72},{98,40}}, textString="h")}),
      Documentation(info="<HTML>
<p><b>Modelling options</b></p>
<p>If <tt>G</tt> is set to zero, the flowrate source is ideal; otherwise, the incoming flowrate increases proportionally to the inlet pressure.</p>
<p>If <tt>w0Fix</tt> is set to true, the incoming flowrate is given by the parameter <tt>w0</tt>; otherwise, the <tt>in_w0</tt> connector must be wired, providing the (possibly varying) source flowrate.</p>
<p>If <tt>hFix</tt> is set to true, the source enthalpy is given by the parameter <tt>h</tt>; otherwise, the <tt>in_h</tt> connector must be wired, providing the (possibly varying) source enthalpy.</p>
</HTML>", revisions="<html>
<ul>
<li><i>16 Dec 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Medium model and standard medium definition added.</li>
<li><i>18 Jun 2004</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Removed <tt>p0_fix</tt> and <tt>hfix</tt>; the connection of external signals is now detected automatically.</li>
<li><i>1 Oct 2003</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       First release.</li>
</ul>
</html>"),
      Diagram(graphics));
  end SinkW;

  model ThroughW "Prescribes the flow rate across the component"
    extends Icons.Water.SourceW;
    extends Modelica.Icons.ObsoleteModel;
    replaceable package Medium = StandardWater constrainedby
      Modelica.Media.Interfaces.PartialMedium "Medium model";
    parameter Medium.MassFlowRate w0=0 "Nominal mass flowrate";
    parameter Boolean allowFlowReversal=system.allowFlowReversal
      "= true to allow flow reversal, false restricts to design direction"
      annotation(Evaluate=true);
    outer ThermoPower.System system "System wide properties";
    Medium.MassFlowRate w "Mass flowrate";
    FlangeA inlet(redeclare package Medium = Medium, m_flow(min=if
            allowFlowReversal then -Modelica.Constants.inf else 0)) annotation (
       Placement(transformation(extent={{-120,-20},{-80,20}}, rotation=0)));
    FlangeB outlet(redeclare package Medium = Medium, m_flow(max=if
            allowFlowReversal then +Modelica.Constants.inf else 0)) annotation (
       Placement(transformation(extent={{80,-20},{120,20}}, rotation=0)));
    Modelica.Blocks.Interfaces.RealInput in_w0 annotation (Placement(
          transformation(
          origin={-40,60},
          extent={{-20,-20},{20,20}},
          rotation=270)));
  equation
    inlet.m_flow + outlet.m_flow = 0 "Mass balance";
    inlet.m_flow = w "Flow characteristics";

    w = in_w0;
    if cardinality(in_w0) == 0 then
      in_w0 = w0 "Flow rate set by parameter";
    end if;

    // Energy balance
    inlet.h_outflow = inStream(outlet.h_outflow);
    inStream(inlet.h_outflow) = outlet.h_outflow;
    annotation (
      Icon(graphics={Text(extent={{-98,72},{-48,40}}, textString="w0")}),
      Documentation(info="<HTML>
This component prescribes the flow rate passing through it. The change of
specific enthalpy due to the pressure difference between the inlet and the
outlet is ignored; use <t>Pump</t> models if this has to be taken into account correctly.
<p><b>Modelling options</b></p>
<p>If <tt>w0Fix</tt> is set to true, the flowrate is given by the parameter <tt>w0</tt>; otherwise, the <tt>in_w0</tt> connector must be wired, providing the (possibly varying) flowrate value.</p>
</HTML>", revisions="<html>
<ul>
<li><i>18 Mar 2005</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       First release.</li>
</ul>
</html>"),
      Diagram(graphics));
  end ThroughW;

  annotation (Documentation(info="<HTML>
This package contains models of physical processes and components using water or steam as working fluid.
<p>All models use the <tt>StandardWater</tt> medium model by default, which is in turn set to <tt>Modelica.Media.Water.StandardWater</tt> at the library level. It is of course possible to redeclare the medium model to any model extending <tt>Modelica.Media.Interfaces.PartialMedium</tt> (or <tt>PartialTwoPhaseMedium</tt> for 2-phase models). This can be done by directly setting Medium in the parameter dialog, or through a local package definition, as shown e.g. in <tt>Test.TestMixerSlowFast</tt>. The latter solution allows to easily replace the medium model for an entire set of components.
<p>All models with dynamic equations provide initialisation support. Set the <tt>initOpt</tt> parameter to the appropriate value:
<ul>
<li><tt>Choices.Init.Options.noInit</tt>: no initialisation
<li><tt>Choices.Init.Options.steadyState</tt>: full steady-state initialisation
<li><tt>Choices.Init.Options.steadyStateNoP</tt>: steady-state initialisation (except pressure)
<li><tt>Choices.Init.Options.steadyStateNoT</tt>: steady-state initialisation (except temperature)
</ul>
The latter options can be useful when two or more components are connected directly so that they will have the same pressure or temperature, to avoid over-specified systems of initial equations.
</HTML>"));
end Water;
