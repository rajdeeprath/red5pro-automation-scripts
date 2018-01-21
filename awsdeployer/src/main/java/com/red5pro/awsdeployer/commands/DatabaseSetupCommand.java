package com.red5pro.awsdeployer.commands;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.io.Reader;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import org.apache.commons.chain.Command;
import org.apache.commons.chain.Context;

import com.amazonaws.AmazonServiceException;
import com.amazonaws.auth.AWSCredentials;
import com.amazonaws.auth.AWSStaticCredentialsProvider;
import com.amazonaws.services.ec2.AmazonEC2;
import com.amazonaws.services.ec2.AmazonEC2ClientBuilder;
import com.amazonaws.services.ec2.model.AmazonEC2Exception;
import com.amazonaws.services.ec2.model.AuthorizeSecurityGroupIngressRequest;
import com.amazonaws.services.ec2.model.CreateSecurityGroupRequest;
import com.amazonaws.services.ec2.model.CreateSecurityGroupResult;
import com.amazonaws.services.ec2.model.CreateTagsRequest;
import com.amazonaws.services.ec2.model.DescribeSecurityGroupsRequest;
import com.amazonaws.services.ec2.model.DescribeSecurityGroupsResult;
import com.amazonaws.services.ec2.model.Filter;
import com.amazonaws.services.ec2.model.IpPermission;
import com.amazonaws.services.ec2.model.IpRange;
import com.amazonaws.services.ec2.model.SecurityGroup;
import com.amazonaws.services.ec2.model.Tag;
import com.amazonaws.services.rds.AmazonRDS;
import com.amazonaws.services.rds.AmazonRDSClient;
import com.amazonaws.services.rds.AmazonRDSClientBuilder;
import com.amazonaws.services.rds.model.CreateDBInstanceRequest;
import com.amazonaws.services.rds.model.CreateDBSecurityGroupRequest;
import com.amazonaws.services.rds.model.DBInstance;
import com.amazonaws.services.rds.model.DBInstanceNotFoundException;
import com.amazonaws.services.rds.model.DBSecurityGroup;
import com.amazonaws.services.rds.model.DBSecurityGroupNotFoundException;
import com.amazonaws.services.rds.model.DescribeDBInstancesRequest;
import com.amazonaws.services.rds.model.DescribeDBInstancesResult;
import com.amazonaws.services.rds.model.DescribeDBSecurityGroupsRequest;
import com.amazonaws.services.rds.model.DescribeDBSecurityGroupsResult;
import com.red5pro.awsdeployer.component.ScriptRunner;
import com.red5pro.awsdeployer.model.Configuration;

public class DatabaseSetupCommand implements Command {
	
	private Configuration configuration;
	
	private AWSCredentials credentials;
	
	private SecurityGroup securityGroup;
	
	private String securityGroupId;
	
	private DBInstance instance;
	
	
	public DatabaseSetupCommand()
	{
		
	}
	

	@Override
	public boolean execute(Context context) throws Exception 
	{
		System.out.println("Preparing database");
		
		this.configuration = (Configuration) context.get("configuration");		
		this.credentials = (AWSCredentials) context.get("credentials");
		
		AmazonRDS client = getRDSClient(configuration.getDbRegion());
		AmazonEC2 ec2Client = getEc2Client2(configuration.getDbRegion());
		
		try
		{
			Filter sessionIdFilter = new Filter().withName("tag:sessionid").withValues(configuration.getSessionId());
			DescribeSecurityGroupsRequest dbSecurityGroupRequest =  new DescribeSecurityGroupsRequest();
			dbSecurityGroupRequest.withGroupNames(configuration.getDbSecurityGroupName());
			dbSecurityGroupRequest.withFilters(new Filter[] {sessionIdFilter});
			
			DescribeSecurityGroupsResult dbSecurityGroupResult =  ec2Client.describeSecurityGroups(dbSecurityGroupRequest);
			List<SecurityGroup> securityGroups = dbSecurityGroupResult.getSecurityGroups();
			
			if(securityGroups.size() > 1)
			{
				System.err.print("An unexpected error occurred. There seems to be two identical security groups!! I dont know what to do next... ");
				throw new Exception("Duplicate security groups detected for database!!!");
			}
			else if(securityGroups.size() == 1)
			{
				securityGroup = securityGroups.get(0);
				securityGroupId = securityGroup.getGroupId();
				System.out.print("DB Security group found by name " + securityGroup.getGroupName() + " in region " + configuration.getDbRegion());
			}
		}
		catch(AmazonEC2Exception e)
		{
			
			if(e.getMessage().contains("' does not exist"))
			{
				List<Tag> dbGroupTags = new ArrayList<Tag>();
				Tag sessionId = new Tag();
				sessionId.setKey("sessionId");
				sessionId.setValue(configuration.getSessionId());
				dbGroupTags.add(sessionId);		
				
				CreateSecurityGroupRequest createSecurityGroupRequest = new CreateSecurityGroupRequest();
				createSecurityGroupRequest.withGroupName(configuration.getDbSecurityGroupName());
				createSecurityGroupRequest.withDescription("Autoscaling database security group");
				
				CreateSecurityGroupResult createGroupResult =  ec2Client.createSecurityGroup(createSecurityGroupRequest);
				securityGroupId = createGroupResult.getGroupId();
				
				List<String> resources = new ArrayList<String>();
				resources.add(securityGroupId);
				
				
				/* Tag security group */
				
				try 
				{
					System.out.println("Tagging security group...");
					
					List<Tag> tags = new ArrayList<Tag>();
					tags.add(new Tag("sessionid", configuration.getSessionId()));
					
					CreateTagsRequest createTagsRequest = new CreateTagsRequest();
					createTagsRequest.setResources(resources);
					createTagsRequest.setTags(tags);
					
					ec2Client.createTags(createTagsRequest);
				} 
				catch (AmazonServiceException ee) 
				{
			        System.err.println("Error tagging resources");
			    	System.err.println("Caught Exception: " + ee.getMessage());
			        System.err.println("Reponse Status Code: " + ee.getStatusCode());
			        System.err.println("Error Code: " + ee.getErrorCode());
			        System.err.println("Request ID: " + ee.getRequestId());
			        
			        throw new Exception("Failed to tag security group " + configuration.getDbSecurityGroupName());
				}
			}
			else
			{
				System.err.println("Error tagging resources");
		    	System.err.println("Caught Exception: " + e.getMessage());
		        System.err.println("Reponse Status Code: " + e.getStatusCode());
		        System.err.println("Error Code: " + e.getErrorCode());
		        System.err.println("Request ID: " + e.getRequestId());
		        
		        throw new Exception("Failed in creating database security group");
			}
			
			
			
			// add permissions
			
			try
			{
				IpPermission ipPermission =	    new IpPermission();
				
				IpRange ipRange1 = new IpRange().withCidrIp("0.0.0.0/0");
				
				// add reserved IP address here
				//IpRange ipRange2 = new IpRange().withCidrIp("150.150.150.150/32");
				
				ipPermission.withIpv4Ranges(Arrays.asList(new IpRange[] {ipRange1}))
	            .withIpProtocol("tcp")
	            .withToPort(3306)
	            .withFromPort(3306);
				
				AuthorizeSecurityGroupIngressRequest authorizeSecurityGroupIngressRequest =    new AuthorizeSecurityGroupIngressRequest();
				authorizeSecurityGroupIngressRequest.withGroupName(configuration.getDbSecurityGroupName()) .withIpPermissions(ipPermission);
				
				ec2Client.authorizeSecurityGroupIngress(authorizeSecurityGroupIngressRequest);
			}
			catch(AmazonServiceException ae)
			{
				throw new Exception("Unable to create firewall rules " + ae.getMessage());
			}
		}
		
		

		// Check and create db
		
		try
		{
			DescribeDBInstancesRequest checkDbReq = new DescribeDBInstancesRequest().withDBInstanceIdentifier(configuration.getDbInstanceName());
			DescribeDBInstancesResult dbResult =  client.describeDBInstances(checkDbReq);
			List<DBInstance> instances = dbResult.getDBInstances();
			instance = instances.get(0);			
		}
		catch(DBInstanceNotFoundException e)
		{
			com.amazonaws.services.rds.model.Tag[] dbInstanceTags = new com.amazonaws.services.rds.model.Tag[1];
			com.amazonaws.services.rds.model.Tag sessionId = new com.amazonaws.services.rds.model.Tag();
			sessionId.setKey("sessionId");
			sessionId.setValue(configuration.getSessionId());
			dbInstanceTags[0] = sessionId;
			
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
	         .withVpcSecurityGroupIds(securityGroupId)
	         .withLicenseModel("general-public-license")
	         .withPubliclyAccessible(true)
	         .withTags(dbInstanceTags);
			
			instance = client.createDBInstance(createDBInstanceRequest);
			
			System.out.println("Waiting for database");
			Thread.sleep(30000);
		}
		
		
		
		while(true)
		{
			try
			{
				// Check and create db
				DescribeDBInstancesRequest checkDbReq = new DescribeDBInstancesRequest().withDBInstanceIdentifier(configuration.getDbInstanceName());
				DescribeDBInstancesResult dbResult =  client.describeDBInstances(checkDbReq);
				List<DBInstance> instances = dbResult.getDBInstances();
				instance = instances.get(0);
				
				String status = instance.getDBInstanceStatus();
				System.out.println("Database status " + status);
				
				if(status.equalsIgnoreCase("stopped"))	
				{
					System.err.println("The instance seems to be ina stopped state");
					throw new Exception("The instance seems to be ina stopped state");
				}
				else
				{
					if(status.equalsIgnoreCase("available"))	
					{
						System.out.println("Database found and is in running state");
						break;
					}
				}
			}
			catch(Exception e)
			{
				throw new Exception("Unexpected error occurred. Could not locate database instance");
			}
			
			System.out.print("Waiting on database");
			Thread.sleep(10000);
		}		 
		 
		 // connect to db and populate the tables if not exists
		 System.out.print("Database is running");
		 
		 
		// Create MySql Connection
		Class.forName("com.mysql.jdbc.Driver");
		String host = instance.getEndpoint().getAddress();
		int port = instance.getEndpoint().getPort();
		Connection con = DriverManager.getConnection("jdbc:mysql://"+host+":"+port+"/" + configuration.getDbSchemaName(), configuration.getDbUsername(), configuration.getDbPassword());
		Statement stmt = null;

		try 
		{
				// Initialize object for ScripRunner
				ScriptRunner sr = new ScriptRunner(con, false, false);

				// Give the input file to Reader
				Reader reader = new BufferedReader( new FileReader(configuration.getSchemaScript()));

				// Exctute script
				sr.runScript(reader);
				
				System.out.print("Script execution complete...");
		} 
		catch ( IOException | SQLException e) 
		{
				System.err.println("Failed to Execute" + configuration.getSchemaScript() 	+ " The error is " + e.getMessage());
		}
		 
		 
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
