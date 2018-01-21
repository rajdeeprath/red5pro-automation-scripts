package com.red5pro.awsdeployer.model;

public class Configuration {
	
	private String awsAccessKey = "aws-key";
	
	private String awsAccessSecret = "aws-secret";
	
	private String defaultRegion;
	
	private String autoscaleVPCName;
	
	private String securityGroupName;
	
	private String imageSourceNodeName;
	
	private String[] streamManagerRegions = {"useast-1"};
	
	private String sessionId = "red5proautoscaling";
	
	private String vpcName = "infrared5vpc";
	
	private String vpcCidr = "10.0.0.0/16";
	
	private String dbInstanceName = "streammanager-db";
	
	private String dbSchemaName = "cluster";
	
	private String dbUsername = "ir5user";
	
	private String dbPassword = "xyz1234567";
	
	private String dbRegion = "useast-1";
	
	private String dbInstanceSize = "db.m1.small";
	
	private String dbEngineVersion = "5.6.37";

	private int dbAllocationSize = 20;
	
	private String dbSecurityGroupName = "autoscalingrds";
	
	private String schemaScript = "C:\\Users\\rajde\\Documents\\GitHub\\red5pro-auto-scaling\\streammanager\\src\\main\\webapp\\WEB-INF\\sql\\cluster.sql";
	

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

	public String getDbSchemaName() {
		return dbSchemaName;
	}

	public void setDbSchemaName(String dbSchemaName) {
		this.dbSchemaName = dbSchemaName;
	}

	public String getDbPassword() {
		return dbPassword;
	}

	public void setDbPassword(String dbPassword) {
		this.dbPassword = dbPassword;
	}

	public String getDbUsername() {
		return dbUsername;
	}

	public void setDbUsername(String dbUsername) {
		this.dbUsername = dbUsername;
	}

	public String getDbInstanceName() {
		return dbInstanceName;
	}

	public void setDbInstanceName(String dbInstanceName) {
		this.dbInstanceName = dbInstanceName;
	}

	public String getDbRegion() {
		return dbRegion;
	}

	public void setDbRegion(String dbRegion) {
		this.dbRegion = dbRegion;
	}

	public String getDbInstanceSize() {
		return dbInstanceSize;
	}

	public void setDbInstanceSize(String dbInstanceSize) {
		this.dbInstanceSize = dbInstanceSize;
	}

	public String getDbEngineVersion() {
		return dbEngineVersion;
	}

	public void setDbEngineVersion(String dbInstanceVersion) {
		this.dbEngineVersion = dbInstanceVersion;
	}

	public int getDbAllocationSize() {
		return dbAllocationSize;
	}

	public void setDbAllocationSize(int dbAllocationSize) {
		this.dbAllocationSize = dbAllocationSize;
	}

	public String getDbSecurityGroupName() {
		return dbSecurityGroupName;
	}

	public void setDbSecurityGroupName(String dbSecurityGroupName) {
		this.dbSecurityGroupName = dbSecurityGroupName;
	}

	public String getSchemaScript() {
		return schemaScript;
	}

	public void setSchemaScript(String schemaScript) {
		this.schemaScript = schemaScript;
	}
	
	
	

}
