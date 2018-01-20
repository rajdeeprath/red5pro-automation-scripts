package com.red5pro.awsdeployer.component;

import org.apache.commons.chain.Context;
import org.apache.commons.chain.impl.ContextBase;

import com.amazonaws.auth.AWSCredentials;
import com.amazonaws.auth.AWSStaticCredentialsProvider;
import com.amazonaws.auth.BasicAWSCredentials;
import com.red5pro.awsdeployer.model.Configuration;

public class AutoScaleDeployerWizard {
	
	private Configuration configuration;
	
	private AWSCredentials credentials;
	
	private Context context;
	
	
	public AutoScaleDeployerWizard() {
		
	}
	
	
	public AutoScaleDeployerWizard(Configuration configuration) {
		this.setConfiguration(configuration);
	}


	public Configuration getConfiguration() {
		return configuration;
	}


	public void setConfiguration(Configuration configuration) {
		this.configuration = configuration;
	}
	
	
	public void initialize()
	{
		credentials = new BasicAWSCredentials(configuration.getAwsAccessKey(), configuration.getAwsAccessSecret());
		
		context = new ContextBase();
		context.put("credentials", credentials);
		context.put("configuration", configuration);
		
		
	}

}
