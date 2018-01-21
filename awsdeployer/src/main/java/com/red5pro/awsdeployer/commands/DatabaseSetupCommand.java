package com.red5pro.awsdeployer.commands;

import java.util.ArrayList;
import java.util.List;

import org.apache.commons.chain.Command;
import org.apache.commons.chain.Context;

import com.amazonaws.auth.AWSCredentials;
import com.amazonaws.auth.AWSStaticCredentialsProvider;
import com.amazonaws.services.ec2.AmazonEC2;
import com.amazonaws.services.ec2.AmazonEC2ClientBuilder;
import com.amazonaws.services.ec2.model.CreateSecurityGroupResult;
import com.amazonaws.services.rds.AmazonRDS;
import com.amazonaws.services.rds.AmazonRDSClient;
import com.amazonaws.services.rds.AmazonRDSClientBuilder;
import com.amazonaws.services.rds.model.CreateDBInstanceRequest;
import com.amazonaws.services.rds.model.CreateDBSecurityGroupRequest;
import com.amazonaws.services.rds.model.DBInstance;
import com.amazonaws.services.rds.model.DBSecurityGroup;
import com.amazonaws.services.rds.model.DescribeDBInstancesRequest;
import com.amazonaws.services.rds.model.DescribeDBInstancesResult;
import com.amazonaws.services.rds.model.DescribeDBSecurityGroupsRequest;
import com.amazonaws.services.rds.model.DescribeDBSecurityGroupsResult;
import com.amazonaws.services.rds.model.Filter;
import com.amazonaws.services.rds.model.Tag;
import com.red5pro.awsdeployer.model.Configuration;

public class DatabaseSetupCommand implements Command {
	
	private Configuration configuration;
	
	private AWSCredentials credentials;
	
	private DBSecurityGroup securityGroup;
	
	private DBInstance instance;
	
	
	public DatabaseSetupCommand()
	{
		
	}
	

	@Override
	public boolean execute(Context context) throws Exception 
	{
		System.out.println("Reserving IP address");
		
		this.configuration = (Configuration) context.get("configuration");		
		this.credentials = (AWSCredentials) context.get("credentials");
		
		AmazonRDS client = getRDSClient(configuration.getDbRegion());
		
		Filter sessionIdFilter = new Filter().withName("tag:sessionid").withValues(configuration.getSessionId());
		
		DescribeDBSecurityGroupsRequest dbSecurityGroupRequest =  new DescribeDBSecurityGroupsRequest().withFilters(new Filter[]{sessionIdFilter}).withDBSecurityGroupName(configuration.getDbSecurityGroupName());
		DescribeDBSecurityGroupsResult dbSecurityGroupResult =  client.describeDBSecurityGroups(dbSecurityGroupRequest);
		List<DBSecurityGroup> securityGroups = dbSecurityGroupResult.getDBSecurityGroups();
		
		
		if(securityGroups.size() > 1)
		{
			System.err.print("An unexpected erro occurred. There seems to be two identical security groups!! I dont know what to do next... ");
			throw new Exception("Duplicate security groups detected for database!!!");
		}
		else if(securityGroups.size() == 1)
		{
			securityGroup = securityGroups.get(0);
			System.out.print("DB Security group found by name " + securityGroup.getDBSecurityGroupName() + " in region " + configuration.getDbRegion());
		}
		else
		{
			List<Tag> dbGroupTags = new ArrayList<Tag>();
			Tag sessionId = new Tag();
			sessionId.setKey("sessionId");
			sessionId.setValue(configuration.getSessionId());
			dbGroupTags.add(sessionId);			
			
			CreateDBSecurityGroupRequest createSecurityGroupRequest = new CreateDBSecurityGroupRequest();
			createSecurityGroupRequest.withDBSecurityGroupName(configuration.getDbSecurityGroupName()).withTags(dbGroupTags);
			securityGroup=  client.createDBSecurityGroup(createSecurityGroupRequest);
			
			System.out.print("DB Security group created by name " + securityGroup.getDBSecurityGroupName() + " in region " + configuration.getDbRegion());
		}
		
		
		// Check and create db
		
		DescribeDBInstancesRequest checkDbReq = new DescribeDBInstancesRequest().withFilters(new Filter[] {sessionIdFilter}).withDBInstanceIdentifier(configuration.getDbInstanceName());
		DescribeDBInstancesResult dbResult =  client.describeDBInstances(checkDbReq);
		List<DBInstance> instances = dbResult.getDBInstances();
		
		if(instances.size() == 0)
		{
			List<Tag> dbInstanceTags = new ArrayList<Tag>();
			Tag sessionId = new Tag();
			sessionId.setKey("sessionId");
			sessionId.setValue(configuration.getSessionId());
			dbInstanceTags.add(sessionId);			
			
			CreateDBInstanceRequest createDBInstanceRequest = new CreateDBInstanceRequest() //
	         .withDBInstanceIdentifier(configuration.getDbInstanceName()) //
	         .withDBName(configuration.getDbSchemaName()) //
	         .withEngine("MySQL") //
	         .withEngineVersion(configuration.getDbEngineVersion()) //
	         .withDBInstanceClass(configuration.getDbInstanceSize()) //
	         .withMasterUsername(configuration.getDbUsername()) //
	         .withMasterUserPassword(configuration.getDbPassword()) //
	         .withAllocatedStorage(configuration.getDbAllocationSize()) //
	         .withBackupRetentionPeriod(0) //
	         .withMultiAZ(false)
	         .withDBSecurityGroups(configuration.getDbSecurityGroupName()) //
	         .withLicenseModel("general-public-license") 
	         .withTags(dbInstanceTags);
			
			instance = client.createDBInstance(createDBInstanceRequest);
		}
		else
		{
			instance = instances.get(0);
		}
		
		
		 // Check for db to be in running state
		 
		 
		 // connect to db and populate the tables if not exists
		 
		 
		 // finish

		return false;
	}

	
	
	AmazonEC2 getEc2Client2(String region){
		AmazonEC2 ec2 = AmazonEC2ClientBuilder.standard()
                .withRegion(region)
                .withCredentials(new AWSStaticCredentialsProvider(credentials))
                .build();
		
		return ec2;
	}

	
	
	AmazonRDS getRDSClient(String region){
		AmazonRDS rds = AmazonRDSClientBuilder.standard()
                .withRegion(region)
                .withCredentials(new AWSStaticCredentialsProvider(credentials))
                .build();
		
		return rds;
	}

}
