package com.red5pro.awsdeployer.model;

public class Configuration {
	
	private String awsAccessKey = "AKIAJCFFDGGDMDDBFH42YIQ";
	
	private String awsAccessSecret = "3jc6zki5ssddgSvs4uSesOrUEERF2gbQWG7+dfJo";
	
	private String defaultRegion;
	
	private String autoscaleVPCName;
	
	private String securityGroupName;
	
	private String imageSourceNodeName;
	
	private String[] streamManagerRegions = {"useast-1"};
	
	private String sessionId = "red5proautoscaling"; // must be unique
	
	private String vpcName = "autoscalingvpc"; // must be unique
	
	private String vpcCidr = "10.0.0.0/16";

	

	public String getAwsAccessSecret() {
		return awsAccessSecret;
	}

	public void setAwsAccessSecret(String awsAccessSecret) {
		this.awsAccessSecret = awsAccessSecret;
	}

	public String getAwsAccessKey() {
		return awsAccessKey;
	}

	public void setAwsAccessKey(String awsAccessKey) {
		this.awsAccessKey = awsAccessKey;
	}

	public String getDefaultRegion() {
		return defaultRegion;
	}

	public void setDefaultRegion(String defaultRegion) {
		this.defaultRegion = defaultRegion;
	}

	public String getAutoscaleVPCName() {
		return autoscaleVPCName;
	}

	public void setAutoscaleVPCName(String autoscaleVPCName) {
		this.autoscaleVPCName = autoscaleVPCName;
	}

	public String getSecurityGroupName() {
		return securityGroupName;
	}

	public void setSecurityGroupName(String securityGroupName) {
		this.securityGroupName = securityGroupName;
	}

	public String getImageSourceNodeName() {
		return imageSourceNodeName;
	}

	public void setImageSourceNodeName(String imageSourceNodeName) {
		this.imageSourceNodeName = imageSourceNodeName;
	}

	public String[] getStreamManagerRegions() {
		return streamManagerRegions;
	}

	public void setStreamManagerRegions(String[] streamManagerRegions) {
		this.streamManagerRegions = streamManagerRegions;
	}

	public String getSessionId() {
		return sessionId;
	}

	public void setSessionId(String sessionId) {
		this.sessionId = sessionId;
	}

	public String getVpcName() {
		return vpcName;
	}

	public void setVpcName(String vpcName) {
		this.vpcName = vpcName;
	}

	public String getVpcCidr() {
		return vpcCidr;
	}

	public void setVpcCidr(String vpcCidr) {
		this.vpcCidr = vpcCidr;
	}
	
	
	

}
