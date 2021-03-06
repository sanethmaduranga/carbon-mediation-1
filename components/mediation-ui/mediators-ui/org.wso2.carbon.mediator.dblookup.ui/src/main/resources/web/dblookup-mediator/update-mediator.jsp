<%@ page language="java" contentType="text/html; charset=ISO-8859-1" pageEncoding="ISO-8859-1"%>
<%--
  ~  Copyright (c) 2008, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
  ~
  ~  Licensed under the Apache License, Version 2.0 (the "License");
  ~  you may not use this file except in compliance with the License.
  ~  You may obtain a copy of the License at
  ~
  ~        http://www.apache.org/licenses/LICENSE-2.0
  ~
  ~  Unless required by applicable law or agreed to in writing, software
  ~  distributed under the License is distributed on an "AS IS" BASIS,
  ~  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  ~  See the License for the specific language governing permissions and
  ~  limitations under the License.
  --%>

<%@ page import="org.wso2.carbon.mediator.service.ui.Mediator" %>
<%@ page import="org.wso2.carbon.mediator.dblookup.DBLookupMediator" %>
<%@ page import="org.wso2.carbon.mediator.dblookup.Statement" %>
<%@ page import="org.apache.synapse.SynapseConstants" %>
<%@ page import="org.apache.synapse.util.xpath.SynapseXPath" %>
<%@ page import="org.wso2.carbon.sequences.ui.util.SequenceEditorHelper" %>
<%@ page import="org.wso2.carbon.sequences.ui.util.ns.XPathFactory" %>
<%@ page import="javax.xml.namespace.QName" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.Iterator" %>

<%
	boolean isDataSource = false;
	boolean isExisiting = false;
	QName qname = null;
	Mediator mediator = SequenceEditorHelper.getEditingMediator(request, session);
	if (!(mediator instanceof DBLookupMediator)) {
		// todo : proper error handling
		throw new RuntimeException("Unable to edit the mediator");
	}
	DBLookupMediator dblookupMediator = (DBLookupMediator) mediator;
	String param = "";
	param = request.getParameter("connectiongroup");
	if (param != null && !param.equals("")) {
		if (param.equals("poolgroup")) {
			isDataSource = false;
		} else if (param.equals("datasourceprop")) {
			isDataSource = true;
			param = request.getParameter("sourceType");
			if (param != null && param.equals("existing")) {
				isExisiting = true;
			}
		}
	}

	ArrayList list = new ArrayList();
	if (!dblookupMediator.getDataSourceProps().isEmpty()) {
		for (Iterator it = dblookupMediator.getDataSourceProps().keySet().iterator(); it.hasNext();) {
			list.add(it.next());
		}
	}
	for (int i = 0; i < list.size(); i++) {
		dblookupMediator.getDataSourceProps().remove(list.get(i));
	}

	if (!isExisiting) {
		param = request.getParameter("url");
		if (param != null && !param.equals("")) {
			qname = new QName(SynapseConstants.SYNAPSE_NAMESPACE, "url");
			dblookupMediator.addDataSourceProperty(qname, param);
		}
		param = request.getParameter("user");
		if (param != null && !param.equals("")) {
			qname = new QName(SynapseConstants.SYNAPSE_NAMESPACE, "user");
			dblookupMediator.addDataSourceProperty(qname, param);
		}
		param = request.getParameter("password");
		if (param != null && !param.equals("")) {
			qname = new QName(SynapseConstants.SYNAPSE_NAMESPACE, "password");
			dblookupMediator.addDataSourceProperty(qname, param);
		}

		if (isDataSource) {
			param = request.getParameter("init_ctx");
			if (param != null && !param.equals("")) {
				qname = new QName(SynapseConstants.SYNAPSE_NAMESPACE, "icClass");
				dblookupMediator.addDataSourceProperty(qname, param);
			}
			param = request.getParameter("ext_data_source");
			if (param != null && !param.equals("")) {
				qname = new QName(SynapseConstants.SYNAPSE_NAMESPACE, "dsName");
				dblookupMediator.addDataSourceProperty(qname, param);
			}
		} else {
			param = request.getParameter("driver");
			if (param != null && !param.equals("")) {
				qname = new QName(SynapseConstants.SYNAPSE_NAMESPACE, "driver");
				dblookupMediator.addDataSourceProperty(qname, param);
			}
		}
		int maxProp = 0;
		/* get the hidden value indicating the max property name */
		param = request.getParameter("hidden_property");
		if (param != null && !param.equals("")) {
			maxProp = Integer.valueOf(param);
		}
		for (int i = 1; i < maxProp; i++) {
			param = request.getParameter("property" + i);
			if (param != null && !param.equals("")) {
				//                qname = new QName(SynapseConstants.SYNAPSE_NAMESPACE, param);
				String key = param;
				param = request.getParameter("property_value" + i);
				if (param != null && !param.equals("")) {
					dblookupMediator.addDataSourceProperty(key, param);
				}
			}
		}
	} else {
		param = request.getParameter("data_source");
		if (param != null && !param.equals("")) {
			qname = new QName(SynapseConstants.SYNAPSE_NAMESPACE, "dsName");
			dblookupMediator.addDataSourceProperty(qname, param);
		}
	}
	/* remove all the statements */
	if (dblookupMediator.getStatementList() != null) {
		while (dblookupMediator.getStatementList().size() > 0) {
			dblookupMediator.getStatementList().remove(0);
		}
	}
	param = request.getParameter("hidden_stmt");
	int maxStmts = 0;
	if (param != null && !param.equals("")) {
		try {
			maxStmts = Integer.valueOf(param);
		} catch (NumberFormatException e) {
		}
	}
	for (int i = 1; i < maxStmts; i++) {
		String sql = request.getParameter("sql_val" + i);
		if (sql != null && !sql.equals("")) {
			Statement statement = new Statement(sql.trim());
			dblookupMediator.addStatement(statement);
			param = request.getParameter("hidden_parameters" + i);
			int maxParams = 0;
			if (param != null && !param.equals("")) {
				try {
					maxParams = Integer.valueOf(param.trim());
				} catch (NumberFormatException e) {
				}
			}
			for (int j = 1; j < maxParams; j++) {
				String param_value = request.getParameter("parameter_value" + i + "." + j);
				SynapseXPath xpath = null;
				if (param_value != null && !param_value.equals("")) {
					String type = request.getParameter("javaType" + i + "." + j);
					if (type != null && !type.equals("")) {
						String paramType =
						                   request.getParameter("parameterType" + i + "." +
						                                        j);
						if (paramType != null) {
							if (paramType.equals("expression")) {
								statement.addParameter(null,
								                       XPathFactory.getInstance()
								                                   .createSynapseXPath("parameter_value" +
								                                                               i +
								                                                               "." +
								                                                               j,
								                                                       request,
								                                                       session),
								                       type);
							} else {
								statement.addParameter(param_value, null, type);
							}
						}
					}
				}
			}
			int maxResults = 0;
			param = request.getParameter("hidden_results" + i);
			if (param != null && !param.equals("")) {
				try {
					maxResults = Integer.parseInt(param.trim());
				} catch (NumberFormatException e) {
				}
			}
			for (int j = 1; j < maxResults; j++) {
				String name = request.getParameter("property_name" + i + "." + j);
				String value = request.getParameter("property_value" + i + "." + j);
				if (name != null && !name.equals("") && value != null && !value.equals("")) {
					statement.addResult(name, value);
				}
			}
		}
	}
%>

